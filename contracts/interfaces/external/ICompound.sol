// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IComet
 * @notice Interface for Compound V3 Comet (cUSDCv3, etc.)
 */
interface IComet {
    /**
     * @notice Supply an amount of asset to the protocol
     * @param asset The asset to supply
     * @param amount The amount to supply
     */
    function supply(address asset, uint256 amount) external;

    /**
     * @notice Supply an amount of asset on behalf of another address
     * @param dst The address to supply on behalf of
     * @param asset The asset to supply
     * @param amount The amount to supply
     */
    function supplyTo(address dst, address asset, uint256 amount) external;

    /**
     * @notice Withdraw an amount of asset from the protocol
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdraw(address asset, uint256 amount) external;

    /**
     * @notice Withdraw an amount of asset to a specific address
     * @param to The address to withdraw to
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawTo(address to, address asset, uint256 amount) external;

    /**
     * @notice Get the balance of an account
     * @param account The account to get balance for
     * @return The balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Get the collateral balance of an account
     * @param account The account
     * @param asset The collateral asset
     * @return The collateral balance
     */
    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    /**
     * @notice Get the base token address
     * @return The base token address
     */
    function baseToken() external view returns (address);

    /**
     * @notice Get the supply rate per second
     * @param utilization The utilization rate
     * @return The supply rate per second
     */
    function getSupplyRate(uint256 utilization) external view returns (uint64);

    /**
     * @notice Get current utilization
     * @return The utilization rate
     */
    function getUtilization() external view returns (uint256);
}

/**
 * @title ICometRewards
 * @notice Interface for Compound V3 Rewards
 */
interface ICometRewards {
    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }

    function claim(address comet, address src, bool shouldAccrue) external;
    function rewardConfig(address comet) external view returns (RewardConfig memory);
    function getRewardOwed(address comet, address account) external returns (address, uint256);
}
