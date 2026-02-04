// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IStrategyManager.sol";

/**
 * @title Vault
 * @notice ERC-4626 compliant yield aggregator vault
 * @dev Main entry point for user deposits/withdrawals with automated yield optimization
 */
contract Vault is ERC20, ReentrancyGuard, Pausable, AccessControl, IVault {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // State variables
    IERC20 private immutable _asset;
    IStrategyManager public strategyManager;
    
    // Configuration
    uint256 public depositLimit;
    uint256 public withdrawalFee; // In basis points (10000 = 100%)
    uint256 public performanceFee; // In basis points
    address public feeRecipient;
    
    // Constants
    uint256 private constant MAX_BPS = 10000;
    uint256 private constant MAX_WITHDRAWAL_FEE = 100; // 1% max
    uint256 private constant MAX_PERFORMANCE_FEE = 2000; // 20% max

    // Events
    event DepositLimitUpdated(uint256 newLimit);
    event StrategyManagerUpdated(address indexed newManager);
    event FeesUpdated(uint256 withdrawalFee, uint256 performanceFee);
    event FeeRecipientUpdated(address indexed newRecipient);

    /**
     * @notice Constructor
     * @param asset_ The underlying asset token
     * @param name_ The vault token name
     * @param symbol_ The vault token symbol
     */
    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _asset = asset_;
        depositLimit = type(uint256).max;
        feeRecipient = msg.sender;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STRATEGIST_ROLE, msg.sender);
        _grantRole(GUARDIAN_ROLE, msg.sender);
    }

    // ============ ERC-4626 View Functions ============

    /// @inheritdoc IVault
    function asset() public view override returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IVault
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = _asset.balanceOf(address(this));
        uint256 strategyAssets = address(strategyManager) != address(0) 
            ? strategyManager.totalAssetsInStrategies() 
            : 0;
        return vaultBalance + strategyAssets;
    }

    /// @inheritdoc IVault
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    /// @inheritdoc IVault
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    /// @inheritdoc IVault
    function maxDeposit(address) public view override returns (uint256) {
        if (paused()) return 0;
        uint256 currentAssets = totalAssets();
        if (currentAssets >= depositLimit) return 0;
        return depositLimit - currentAssets;
    }

    /// @inheritdoc IVault
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    /// @inheritdoc IVault
    function maxMint(address receiver) public view override returns (uint256) {
        return convertToShares(maxDeposit(receiver));
    }

    /// @inheritdoc IVault
    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets() + supply - 1) / supply;
    }

    /// @inheritdoc IVault
    function maxWithdraw(address owner) public view override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /// @inheritdoc IVault
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply + totalAssets() - 1) / totalAssets();
    }

    /// @inheritdoc IVault
    function maxRedeem(address owner) public view override returns (uint256) {
        return balanceOf(owner);
    }

    /// @inheritdoc IVault
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    // ============ ERC-4626 Mutative Functions ============

    /// @inheritdoc IVault
    function deposit(uint256 assets, address receiver) 
        public 
        override 
        nonReentrant 
        whenNotPaused 
        returns (uint256 shares) 
    {
        require(assets > 0, "Vault: zero deposit");
        require(assets <= maxDeposit(receiver), "Vault: deposit exceeds limit");

        shares = previewDeposit(assets);
        require(shares > 0, "Vault: zero shares");

        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IVault
    function mint(uint256 shares, address receiver) 
        public 
        override 
        nonReentrant 
        whenNotPaused 
        returns (uint256 assets) 
    {
        require(shares > 0, "Vault: zero shares");

        assets = previewMint(shares);
        require(assets <= maxDeposit(receiver), "Vault: mint exceeds limit");

        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @inheritdoc IVault
    function withdraw(uint256 assets, address receiver, address owner) 
        public 
        override 
        nonReentrant 
        returns (uint256 shares) 
    {
        require(assets > 0, "Vault: zero withdraw");

        shares = previewWithdraw(assets);
        
        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(allowed >= shares, "Vault: allowance exceeded");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        _burn(owner, shares);
        
        // Ensure we have enough assets, withdraw from strategies if needed
        _ensureLiquidity(assets);
        
        // Apply withdrawal fee
        uint256 fee = (assets * withdrawalFee) / MAX_BPS;
        uint256 assetsAfterFee = assets - fee;
        
        if (fee > 0 && feeRecipient != address(0)) {
            _asset.safeTransfer(feeRecipient, fee);
        }
        
        _asset.safeTransfer(receiver, assetsAfterFee);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @inheritdoc IVault
    function redeem(uint256 shares, address receiver, address owner) 
        public 
        override 
        nonReentrant 
        returns (uint256 assets) 
    {
        require(shares > 0, "Vault: zero redeem");
        require(shares <= maxRedeem(owner), "Vault: redeem exceeds balance");

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                require(allowed >= shares, "Vault: allowance exceeded");
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        assets = previewRedeem(shares);
        _burn(owner, shares);
        
        // Ensure we have enough assets
        _ensureLiquidity(assets);
        
        // Apply withdrawal fee
        uint256 fee = (assets * withdrawalFee) / MAX_BPS;
        uint256 assetsAfterFee = assets - fee;
        
        if (fee > 0 && feeRecipient != address(0)) {
            _asset.safeTransfer(feeRecipient, fee);
        }
        
        _asset.safeTransfer(receiver, assetsAfterFee);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    // ============ Internal Functions ============

    /**
     * @notice Ensures the vault has enough liquid assets
     * @param amount The amount needed
     */
    function _ensureLiquidity(uint256 amount) internal {
        uint256 vaultBalance = _asset.balanceOf(address(this));
        if (vaultBalance < amount && address(strategyManager) != address(0)) {
            uint256 needed = amount - vaultBalance;
            strategyManager.withdrawFromStrategies(needed);
        }
    }

    // ============ Admin Functions ============

    /**
     * @notice Sets the strategy manager
     * @param manager The new strategy manager address
     */
    function setStrategyManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyManager = IStrategyManager(manager);
        emit StrategyManagerUpdated(manager);
    }

    /**
     * @notice Sets the deposit limit
     * @param limit The new deposit limit
     */
    function setDepositLimit(uint256 limit) external onlyRole(STRATEGIST_ROLE) {
        depositLimit = limit;
        emit DepositLimitUpdated(limit);
    }

    /**
     * @notice Sets the fees
     * @param _withdrawalFee New withdrawal fee in basis points
     * @param _performanceFee New performance fee in basis points
     */
    function setFees(uint256 _withdrawalFee, uint256 _performanceFee) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_withdrawalFee <= MAX_WITHDRAWAL_FEE, "Vault: withdrawal fee too high");
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "Vault: performance fee too high");
        withdrawalFee = _withdrawalFee;
        performanceFee = _performanceFee;
        emit FeesUpdated(_withdrawalFee, _performanceFee);
    }

    /**
     * @notice Sets the fee recipient
     * @param recipient The new fee recipient
     */
    function setFeeRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), "Vault: zero address");
        feeRecipient = recipient;
        emit FeeRecipientUpdated(recipient);
    }

    /**
     * @notice Deposits idle assets into strategies
     */
    function depositToStrategies() external onlyRole(STRATEGIST_ROLE) {
        require(address(strategyManager) != address(0), "Vault: no strategy manager");
        uint256 available = _asset.balanceOf(address(this));
        if (available > 0) {
            _asset.safeTransfer(address(strategyManager), available);
            strategyManager.depositToStrategies(available);
        }
    }

    // ============ Guardian Functions ============

    /**
     * @notice Pauses the vault
     */
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the vault
     */
    function unpause() external onlyRole(GUARDIAN_ROLE) {
        _unpause();
    }

    /**
     * @notice Emergency withdraw all from strategies
     */
    function emergencyWithdraw() external onlyRole(GUARDIAN_ROLE) {
        if (address(strategyManager) != address(0)) {
            strategyManager.emergencyWithdrawAll();
        }
    }
}
