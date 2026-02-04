// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IVault
 * @notice Interface for the main yield aggregator vault
 * @dev Follows ERC-4626 tokenized vault standard
 */
interface IVault is IERC20 {
    /// @notice Returns the address of the underlying asset
    function asset() external view returns (address);

    /// @notice Returns the total assets held by the vault
    function totalAssets() external view returns (uint256);

    /// @notice Converts assets to shares
    /// @param assets Amount of assets
    /// @return shares Equivalent amount of shares
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Converts shares to assets
    /// @param shares Amount of shares
    /// @return assets Equivalent amount of assets
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Returns the maximum amount that can be deposited
    /// @param receiver The receiver of shares
    /// @return maxAssets Maximum deposit amount
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /// @notice Preview the shares received for a deposit
    /// @param assets Amount of assets to deposit
    /// @return shares Amount of shares that would be minted
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Deposits assets and mints shares
    /// @param assets Amount of assets to deposit
    /// @param receiver Address to receive the shares
    /// @return shares Amount of shares minted
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Returns the maximum amount that can be minted
    /// @param receiver The receiver of shares
    /// @return maxShares Maximum mint amount
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /// @notice Preview the assets required for minting
    /// @param shares Amount of shares to mint
    /// @return assets Amount of assets required
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /// @notice Mints shares by depositing assets
    /// @param shares Amount of shares to mint
    /// @param receiver Address to receive the shares
    /// @return assets Amount of assets deposited
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /// @notice Returns the maximum amount that can be withdrawn
    /// @param owner The owner of shares
    /// @return maxAssets Maximum withdrawal amount
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /// @notice Preview the shares burned for a withdrawal
    /// @param assets Amount of assets to withdraw
    /// @return shares Amount of shares that would be burned
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /// @notice Withdraws assets by burning shares
    /// @param assets Amount of assets to withdraw
    /// @param receiver Address to receive the assets
    /// @param owner Owner of the shares
    /// @return shares Amount of shares burned
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /// @notice Returns the maximum amount that can be redeemed
    /// @param owner The owner of shares
    /// @return maxShares Maximum redeem amount
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /// @notice Preview the assets received for redeeming
    /// @param shares Amount of shares to redeem
    /// @return assets Amount of assets that would be received
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /// @notice Redeems shares for assets
    /// @param shares Amount of shares to redeem
    /// @param receiver Address to receive the assets
    /// @param owner Owner of the shares
    /// @return assets Amount of assets received
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    // Events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event StrategyUpdated(address indexed strategy, bool active);
}
