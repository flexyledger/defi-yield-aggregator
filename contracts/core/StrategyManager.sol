// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IStrategy.sol";

/**
 * @title StrategyManager
 * @notice Manages multiple yield strategies and handles allocation/rebalancing
 */
contract StrategyManager is ReentrancyGuard, AccessControl, IStrategyManager {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    // State
    address public immutable override vault;
    IERC20 public immutable asset;
    
    address[] private _strategies;
    mapping(address => StrategyInfo) private _strategyInfo;
    mapping(address => uint256) private _strategyIndex;
    
    // Configuration
    uint256 public constant MAX_STRATEGIES = 10;
    uint256 public constant MAX_BPS = 10000;

    // Events (from interface plus additional)
    event DepositedToStrategy(address indexed strategy, uint256 amount);
    event WithdrawnFromStrategy(address indexed strategy, uint256 amount);

    /**
     * @notice Constructor
     * @param _vault The vault address
     * @param _asset The underlying asset
     */
    constructor(address _vault, address _asset) {
        require(_vault != address(0), "SM: zero vault");
        require(_asset != address(0), "SM: zero asset");
        
        vault = _vault;
        asset = IERC20(_asset);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STRATEGIST_ROLE, msg.sender);
        _grantRole(VAULT_ROLE, _vault);
    }

    // ============ View Functions ============

    /// @inheritdoc IStrategyManager
    function totalStrategies() external view override returns (uint256) {
        return _strategies.length;
    }

    /// @inheritdoc IStrategyManager
    function getStrategy(uint256 index) external view override returns (StrategyInfo memory) {
        require(index < _strategies.length, "SM: index out of bounds");
        return _strategyInfo[_strategies[index]];
    }

    /// @inheritdoc IStrategyManager
    function getStrategyAllocation(address strategy) external view override returns (uint256) {
        return _strategyInfo[strategy].allocationBps;
    }

    /// @inheritdoc IStrategyManager
    function totalAssetsInStrategies() public view override returns (uint256 total) {
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_strategyInfo[_strategies[i]].isActive) {
                total += IStrategy(_strategies[i]).estimatedTotalAssets();
            }
        }
    }

    /**
     * @notice Returns all strategy addresses
     */
    function getAllStrategies() external view returns (address[] memory) {
        return _strategies;
    }

    // ============ Strategy Management ============

    /// @inheritdoc IStrategyManager
    function addStrategy(address strategy, uint256 allocationBps) 
        external 
        override 
        onlyRole(STRATEGIST_ROLE) 
    {
        require(strategy != address(0), "SM: zero address");
        require(_strategies.length < MAX_STRATEGIES, "SM: max strategies");
        require(!_strategyInfo[strategy].isActive, "SM: already added");
        require(IStrategy(strategy).want() == address(asset), "SM: wrong asset");
        require(_validateTotalAllocation(allocationBps), "SM: allocation exceeds 100%");

        _strategyIndex[strategy] = _strategies.length;
        _strategies.push(strategy);
        
        _strategyInfo[strategy] = StrategyInfo({
            strategyAddress: strategy,
            allocationBps: allocationBps,
            totalDeposited: 0,
            lastHarvest: block.timestamp,
            isActive: true
        });

        // Approve strategy to spend asset
        asset.safeIncreaseAllowance(strategy, type(uint256).max);

        emit StrategyAdded(strategy, allocationBps);
    }

    /// @inheritdoc IStrategyManager
    function removeStrategy(address strategy) external override onlyRole(STRATEGIST_ROLE) {
        require(_strategyInfo[strategy].isActive, "SM: not active");

        // Withdraw all from strategy first
        IStrategy(strategy).withdrawAll();
        
        // Remove approval
        asset.safeApprove(strategy, 0);

        // Remove from array (swap and pop)
        uint256 index = _strategyIndex[strategy];
        uint256 lastIndex = _strategies.length - 1;
        
        if (index != lastIndex) {
            address lastStrategy = _strategies[lastIndex];
            _strategies[index] = lastStrategy;
            _strategyIndex[lastStrategy] = index;
        }
        
        _strategies.pop();
        delete _strategyIndex[strategy];
        delete _strategyInfo[strategy];

        emit StrategyRemoved(strategy);
    }

    /// @inheritdoc IStrategyManager
    function updateAllocation(address strategy, uint256 allocationBps) 
        external 
        override 
        onlyRole(STRATEGIST_ROLE) 
    {
        require(_strategyInfo[strategy].isActive, "SM: not active");
        
        uint256 oldAllocation = _strategyInfo[strategy].allocationBps;
        uint256 totalOther = _getTotalAllocationExcluding(strategy);
        require(totalOther + allocationBps <= MAX_BPS, "SM: allocation exceeds 100%");

        _strategyInfo[strategy].allocationBps = allocationBps;

        emit AllocationUpdated(strategy, oldAllocation, allocationBps);
    }

    // ============ Deposit/Withdraw ============

    /// @inheritdoc IStrategyManager
    function depositToStrategies(uint256 amount) external override onlyRole(VAULT_ROLE) nonReentrant {
        require(amount > 0, "SM: zero amount");
        
        uint256 remaining = amount;
        
        for (uint256 i = 0; i < _strategies.length && remaining > 0; i++) {
            StrategyInfo storage info = _strategyInfo[_strategies[i]];
            if (!info.isActive || info.allocationBps == 0) continue;

            uint256 strategyAmount = (amount * info.allocationBps) / MAX_BPS;
            if (strategyAmount > remaining) strategyAmount = remaining;
            
            if (strategyAmount > 0) {
                asset.safeTransfer(_strategies[i], strategyAmount);
                IStrategy(_strategies[i]).deposit();
                info.totalDeposited += strategyAmount;
                remaining -= strategyAmount;
                
                emit DepositedToStrategy(_strategies[i], strategyAmount);
            }
        }
    }

    /// @inheritdoc IStrategyManager
    function withdrawFromStrategies(uint256 amount) 
        external 
        override 
        onlyRole(VAULT_ROLE) 
        nonReentrant 
        returns (uint256 withdrawn) 
    {
        require(amount > 0, "SM: zero amount");
        
        uint256 remaining = amount;
        
        // Withdraw proportionally from each strategy
        for (uint256 i = 0; i < _strategies.length && remaining > 0; i++) {
            StrategyInfo storage info = _strategyInfo[_strategies[i]];
            if (!info.isActive) continue;

            uint256 strategyAssets = IStrategy(_strategies[i]).estimatedTotalAssets();
            if (strategyAssets == 0) continue;

            uint256 toWithdraw = remaining > strategyAssets ? strategyAssets : remaining;
            uint256 actual = IStrategy(_strategies[i]).withdraw(toWithdraw);
            
            withdrawn += actual;
            remaining -= actual;
            info.totalDeposited = info.totalDeposited > actual ? info.totalDeposited - actual : 0;
            
            emit WithdrawnFromStrategy(_strategies[i], actual);
        }

        // Transfer withdrawn assets to vault
        if (withdrawn > 0) {
            asset.safeTransfer(vault, withdrawn);
        }
    }

    // ============ Harvest & Rebalance ============

    /// @inheritdoc IStrategyManager
    function harvest(address strategy) public override onlyRole(STRATEGIST_ROLE) {
        require(_strategyInfo[strategy].isActive, "SM: not active");
        
        uint256 beforeBalance = asset.balanceOf(address(this));
        IStrategy(strategy).harvest();
        uint256 afterBalance = asset.balanceOf(address(this));
        
        uint256 profit = afterBalance > beforeBalance ? afterBalance - beforeBalance : 0;
        _strategyInfo[strategy].lastHarvest = block.timestamp;

        emit Harvested(strategy, profit);
    }

    /// @inheritdoc IStrategyManager
    function harvestAll() external override onlyRole(STRATEGIST_ROLE) {
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_strategyInfo[_strategies[i]].isActive) {
                harvest(_strategies[i]);
            }
        }
    }

    /// @inheritdoc IStrategyManager
    function rebalance() external override onlyRole(STRATEGIST_ROLE) nonReentrant {
        uint256 totalAssets = asset.balanceOf(address(this)) + totalAssetsInStrategies();
        if (totalAssets == 0) return;

        // First, withdraw everything
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_strategyInfo[_strategies[i]].isActive) {
                IStrategy(_strategies[i]).withdrawAll();
            }
        }

        // Then, redistribute according to allocations
        uint256 available = asset.balanceOf(address(this));
        
        for (uint256 i = 0; i < _strategies.length; i++) {
            StrategyInfo storage info = _strategyInfo[_strategies[i]];
            if (!info.isActive || info.allocationBps == 0) continue;

            uint256 targetAmount = (available * info.allocationBps) / MAX_BPS;
            if (targetAmount > 0) {
                asset.safeTransfer(_strategies[i], targetAmount);
                IStrategy(_strategies[i]).deposit();
                info.totalDeposited = targetAmount;
            }
        }

        emit Rebalanced(block.timestamp);
    }

    // ============ Emergency ============

    /// @inheritdoc IStrategyManager
    function emergencyWithdrawAll() external override onlyRole(VAULT_ROLE) {
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_strategyInfo[_strategies[i]].isActive) {
                try IStrategy(_strategies[i]).emergencyWithdraw() {} catch {}
            }
        }
        
        // Transfer all assets to vault
        uint256 balance = asset.balanceOf(address(this));
        if (balance > 0) {
            asset.safeTransfer(vault, balance);
        }
    }

    // ============ Internal ============

    function _validateTotalAllocation(uint256 newAllocation) internal view returns (bool) {
        uint256 total = newAllocation;
        for (uint256 i = 0; i < _strategies.length; i++) {
            total += _strategyInfo[_strategies[i]].allocationBps;
        }
        return total <= MAX_BPS;
    }

    function _getTotalAllocationExcluding(address strategy) internal view returns (uint256 total) {
        for (uint256 i = 0; i < _strategies.length; i++) {
            if (_strategies[i] != strategy) {
                total += _strategyInfo[_strategies[i]].allocationBps;
            }
        }
    }
}
