// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IStrategyManager
 * @notice Interface for the strategy manager that orchestrates multiple strategies
 */
interface IStrategyManager {
    /// @notice Strategy information struct
    struct StrategyInfo {
        address strategyAddress;
        uint256 allocationBps;      // Allocation in basis points (10000 = 100%)
        uint256 totalDeposited;
        uint256 lastHarvest;
        bool isActive;
    }

    /// @notice Returns the vault address
    function vault() external view returns (address);

    /// @notice Returns the total number of strategies
    function totalStrategies() external view returns (uint256);

    /// @notice Returns strategy info by index
    /// @param index The strategy index
    /// @return info The strategy information
    function getStrategy(uint256 index) external view returns (StrategyInfo memory info);

    /// @notice Returns strategy allocation in basis points
    /// @param strategy The strategy address
    /// @return allocationBps The allocation in basis points
    function getStrategyAllocation(address strategy) external view returns (uint256 allocationBps);

    /// @notice Adds a new strategy
    /// @param strategy The strategy address
    /// @param allocationBps Initial allocation in basis points
    function addStrategy(address strategy, uint256 allocationBps) external;

    /// @notice Removes a strategy
    /// @param strategy The strategy address
    function removeStrategy(address strategy) external;

    /// @notice Updates strategy allocation
    /// @param strategy The strategy address
    /// @param allocationBps New allocation in basis points
    function updateAllocation(address strategy, uint256 allocationBps) external;

    /// @notice Rebalances assets across all strategies
    function rebalance() external;

    /// @notice Harvests rewards from all strategies
    function harvestAll() external;

    /// @notice Harvests rewards from a specific strategy
    /// @param strategy The strategy address
    function harvest(address strategy) external;

    /// @notice Deposits assets into strategies based on allocation
    /// @param amount The amount to deposit
    function depositToStrategies(uint256 amount) external;

    /// @notice Withdraws assets from strategies
    /// @param amount The amount to withdraw
    /// @return withdrawn The actual amount withdrawn
    function withdrawFromStrategies(uint256 amount) external returns (uint256 withdrawn);

    /// @notice Returns the total assets across all strategies
    function totalAssetsInStrategies() external view returns (uint256);

    /// @notice Emergency withdraws from all strategies
    function emergencyWithdrawAll() external;

    // Events
    event StrategyAdded(address indexed strategy, uint256 allocationBps);
    event StrategyRemoved(address indexed strategy);
    event AllocationUpdated(address indexed strategy, uint256 oldAllocation, uint256 newAllocation);
    event Rebalanced(uint256 timestamp);
    event Harvested(address indexed strategy, uint256 profit);
}
