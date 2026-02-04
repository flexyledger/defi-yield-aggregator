// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStrategy.sol";

/**
 * @title BaseStrategy
 * @notice Abstract base contract for all yield strategies
 * @dev Provides common functionality for strategy implementations
 */
abstract contract BaseStrategy is IStrategy, Ownable {
    using SafeERC20 for IERC20;

    // State
    address public immutable override vault;
    IERC20 public immutable wantToken;
    string private _name;
    bool private _isActive;

    // Events
    event StrategyActivated();
    event StrategyDeactivated();

    modifier onlyVault() {
        require(msg.sender == vault, "BaseStrategy: not vault");
        _;
    }

    modifier onlyVaultOrOwner() {
        require(msg.sender == vault || msg.sender == owner(), "BaseStrategy: not authorized");
        _;
    }

    /**
     * @notice Constructor
     * @param _vault The vault address
     * @param _want The want token address
     * @param strategyName The strategy name
     */
    constructor(
        address _vault,
        address _want,
        string memory strategyName
    ) Ownable(msg.sender) {
        require(_vault != address(0), "BaseStrategy: zero vault");
        require(_want != address(0), "BaseStrategy: zero want");
        
        vault = _vault;
        wantToken = IERC20(_want);
        _name = strategyName;
        _isActive = true;
    }

    // ============ View Functions ============

    /// @inheritdoc IStrategy
    function want() external view override returns (address) {
        return address(wantToken);
    }

    /// @inheritdoc IStrategy
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IStrategy
    function isActive() external view override returns (bool) {
        return _isActive;
    }

    /// @inheritdoc IStrategy
    function estimatedTotalAssets() public view virtual override returns (uint256) {
        return wantToken.balanceOf(address(this)) + _deployedBalance();
    }

    // ============ Core Functions ============

    /// @inheritdoc IStrategy
    function deposit() external virtual override onlyVaultOrOwner {
        uint256 available = wantToken.balanceOf(address(this));
        if (available > 0) {
            _deposit(available);
            emit Deposited(available);
        }
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external virtual override onlyVaultOrOwner returns (uint256) {
        require(amount > 0, "BaseStrategy: zero amount");
        
        uint256 balance = wantToken.balanceOf(address(this));
        
        if (balance < amount) {
            uint256 needed = amount - balance;
            _withdraw(needed);
            balance = wantToken.balanceOf(address(this));
        }

        uint256 toWithdraw = balance < amount ? balance : amount;
        wantToken.safeTransfer(vault, toWithdraw);
        
        emit Withdrawn(toWithdraw);
        return toWithdraw;
    }

    /// @inheritdoc IStrategy
    function withdrawAll() external virtual override onlyVaultOrOwner returns (uint256) {
        _withdrawAll();
        
        uint256 balance = wantToken.balanceOf(address(this));
        if (balance > 0) {
            wantToken.safeTransfer(vault, balance);
        }
        
        emit Withdrawn(balance);
        return balance;
    }

    /// @inheritdoc IStrategy
    function harvest() external virtual override onlyVaultOrOwner {
        uint256 before = estimatedTotalAssets();
        _harvest();
        uint256 after_ = estimatedTotalAssets();
        
        uint256 profit = after_ > before ? after_ - before : 0;
        uint256 loss = before > after_ ? before - after_ : 0;
        
        emit Harvested(profit, loss);
    }

    /// @inheritdoc IStrategy
    function emergencyWithdraw() external virtual override onlyVaultOrOwner {
        _emergencyWithdraw();
        
        uint256 balance = wantToken.balanceOf(address(this));
        if (balance > 0) {
            wantToken.safeTransfer(vault, balance);
        }
        
        _isActive = false;
        emit EmergencyWithdrawal(balance);
    }

    // ============ Admin Functions ============

    /**
     * @notice Activates the strategy
     */
    function activate() external onlyOwner {
        _isActive = true;
        emit StrategyActivated();
    }

    /**
     * @notice Deactivates the strategy
     */
    function deactivate() external onlyOwner {
        _isActive = false;
        emit StrategyDeactivated();
    }

    /**
     * @notice Rescues tokens sent to this contract by mistake
     * @param token The token to rescue
     * @param amount The amount to rescue
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(wantToken), "BaseStrategy: cannot rescue want");
        IERC20(token).safeTransfer(owner(), amount);
    }

    // ============ Internal Functions (to be implemented) ============

    /**
     * @notice Returns the balance deployed in the protocol
     */
    function _deployedBalance() internal view virtual returns (uint256);

    /**
     * @notice Deposits funds into the protocol
     * @param amount Amount to deposit
     */
    function _deposit(uint256 amount) internal virtual;

    /**
     * @notice Withdraws funds from the protocol
     * @param amount Amount to withdraw
     */
    function _withdraw(uint256 amount) internal virtual;

    /**
     * @notice Withdraws all funds from the protocol
     */
    function _withdrawAll() internal virtual;

    /**
     * @notice Harvests rewards from the protocol
     */
    function _harvest() internal virtual;

    /**
     * @notice Emergency withdrawal (may incur losses)
     */
    function _emergencyWithdraw() internal virtual;
}
