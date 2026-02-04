// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IStrategy
 * @notice Interface for yield strategy adapters
 * @dev All protocol strategy adapters must implement this interface
 */
interface IStrategy {
    /// @notice Returns the address of the vault this strategy belongs to
    function vault() external view returns (address);

    /// @notice Returns the address of the token this strategy accepts
    function want() external view returns (address);

    /// @notice Returns the name of this strategy
    function name() external view returns (string memory);

    /// @notice Deposits all available `want` tokens into the strategy
    function deposit() external;

    /// @notice Withdraws a specific amount of `want` tokens
    /// @param amount The amount to withdraw
    /// @return The actual amount withdrawn
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice Withdraws all assets from the strategy
    /// @return The total amount withdrawn
    function withdrawAll() external returns (uint256);

    /// @notice Harvests rewards and reinvests them
    function harvest() external;

    /// @notice Returns the total assets held by this strategy
    /// @return The estimated total assets in `want` token
    function estimatedTotalAssets() external view returns (uint256);

    /// @notice Returns the current APR of this strategy (in basis points)
    /// @return The APR in basis points (10000 = 100%)
    function apr() external view returns (uint256);

    /// @notice Emergency function to withdraw all funds to the vault
    function emergencyWithdraw() external;

    /// @notice Returns whether this strategy is active
    function isActive() external view returns (bool);

    // Events
    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event Harvested(uint256 profit, uint256 loss);
    event EmergencyWithdrawal(uint256 amount);
}
