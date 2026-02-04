// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStrategy.sol";
import "../interfaces/external/IAave.sol";

/**
 * @title AaveStrategy
 * @notice Strategy for depositing assets into Aave V3 lending pools
 */
contract AaveStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    // Aave contracts
    IAavePool public immutable aavePool;
    IERC20 public immutable aToken;

    // Constants
    uint16 private constant REFERRAL_CODE = 0;
    uint256 private constant RAY = 1e27;

    /**
     * @notice Constructor
     * @param _vault The vault address
     * @param _want The want token address (e.g., USDC)
     * @param _aavePool The Aave V3 pool address
     */
    constructor(
        address _vault,
        address _want,
        address _aavePool
    ) BaseStrategy(_vault, _want, "Aave V3 Strategy") {
        require(_aavePool != address(0), "AaveStrategy: zero pool");
        
        aavePool = IAavePool(_aavePool);
        
        // Get aToken address from pool
        IAavePool.ReserveData memory reserveData = aavePool.getReserveData(_want);
        require(reserveData.aTokenAddress != address(0), "AaveStrategy: asset not supported");
        aToken = IERC20(reserveData.aTokenAddress);

        // Approve pool to spend want token
        IERC20(_want).safeApprove(_aavePool, type(uint256).max);
    }

    // ============ View Functions ============

    /// @inheritdoc IStrategy
    function apr() external view override returns (uint256) {
        IAavePool.ReserveData memory data = aavePool.getReserveData(address(wantToken));
        // Convert from RAY (27 decimals) to basis points (4 decimals)
        // currentLiquidityRate is in RAY, represents APY
        return uint256(data.currentLiquidityRate) * 10000 / RAY;
    }

    // ============ Internal Functions ============

    /// @inheritdoc BaseStrategy
    function _deployedBalance() internal view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /// @inheritdoc BaseStrategy
    function _deposit(uint256 amount) internal override {
        aavePool.supply(address(wantToken), amount, address(this), REFERRAL_CODE);
    }

    /// @inheritdoc BaseStrategy
    function _withdraw(uint256 amount) internal override {
        aavePool.withdraw(address(wantToken), amount, address(this));
    }

    /// @inheritdoc BaseStrategy
    function _withdrawAll() internal override {
        uint256 balance = aToken.balanceOf(address(this));
        if (balance > 0) {
            aavePool.withdraw(address(wantToken), type(uint256).max, address(this));
        }
    }

    /// @inheritdoc BaseStrategy
    function _harvest() internal override {
        // Aave automatically accrues interest to aToken balance
        // No explicit harvest needed, but we can compound by doing nothing
        // In future, can claim additional rewards from Aave incentives controller
    }

    /// @inheritdoc BaseStrategy
    function _emergencyWithdraw() internal override {
        _withdrawAll();
    }
}
