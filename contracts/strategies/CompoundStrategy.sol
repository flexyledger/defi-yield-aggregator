// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseStrategy.sol";
import "../interfaces/external/ICompound.sol";

/**
 * @title CompoundStrategy
 * @notice Strategy for supplying assets to Compound V3 (Comet)
 */
contract CompoundStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    // Compound contracts
    IComet public immutable comet;
    ICometRewards public immutable cometRewards;
    IERC20 public immutable compToken;

    // Constants
    uint256 private constant SECONDS_PER_YEAR = 365 days;

    /**
     * @notice Constructor
     * @param _vault The vault address
     * @param _comet The Compound V3 Comet address (e.g., cUSDCv3)
     * @param _cometRewards The Comet rewards contract
     * @param _compToken The COMP token address
     */
    constructor(
        address _vault,
        address _comet,
        address _cometRewards,
        address _compToken
    ) BaseStrategy(_vault, IComet(_comet).baseToken(), "Compound V3 Strategy") {
        require(_comet != address(0), "CompoundStrategy: zero comet");
        
        comet = IComet(_comet);
        cometRewards = ICometRewards(_cometRewards);
        compToken = IERC20(_compToken);

        // Approve comet to spend want token
        IERC20(IComet(_comet).baseToken()).safeApprove(_comet, type(uint256).max);
    }

    // ============ View Functions ============

    /// @inheritdoc IStrategy
    function apr() external view override returns (uint256) {
        uint256 utilization = comet.getUtilization();
        uint64 supplyRate = comet.getSupplyRate(utilization);
        // Convert per-second rate to APR in basis points
        // supplyRate is scaled by 1e18
        return (uint256(supplyRate) * SECONDS_PER_YEAR * 10000) / 1e18;
    }

    // ============ Internal Functions ============

    /// @inheritdoc BaseStrategy
    function _deployedBalance() internal view override returns (uint256) {
        return comet.balanceOf(address(this));
    }

    /// @inheritdoc BaseStrategy
    function _deposit(uint256 amount) internal override {
        comet.supply(address(wantToken), amount);
    }

    /// @inheritdoc BaseStrategy
    function _withdraw(uint256 amount) internal override {
        comet.withdraw(address(wantToken), amount);
    }

    /// @inheritdoc BaseStrategy
    function _withdrawAll() internal override {
        uint256 balance = comet.balanceOf(address(this));
        if (balance > 0) {
            comet.withdraw(address(wantToken), balance);
        }
    }

    /// @inheritdoc BaseStrategy
    function _harvest() internal override {
        // Claim COMP rewards
        if (address(cometRewards) != address(0)) {
            cometRewards.claim(address(comet), address(this), true);
        }
        
        // Swap COMP to want token would happen here
        // For now, just collect the rewards
        uint256 compBalance = compToken.balanceOf(address(this));
        if (compBalance > 0) {
            // In production, integrate with DEX to swap COMP -> want
            // For now, send to vault as reward
            compToken.safeTransfer(vault, compBalance);
        }
    }

    /// @inheritdoc BaseStrategy
    function _emergencyWithdraw() internal override {
        _withdrawAll();
    }
}
