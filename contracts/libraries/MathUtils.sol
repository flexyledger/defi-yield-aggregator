// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MathUtils
 * @notice Math utility functions for the yield aggregator
 */
library MathUtils {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant MAX_BPS = 10000;

    /**
     * @notice Calculates percentage of a value in basis points
     * @param value The value to calculate percentage of
     * @param bps Basis points (10000 = 100%)
     * @return The calculated percentage
     */
    function bpsOf(uint256 value, uint256 bps) internal pure returns (uint256) {
        return (value * bps) / MAX_BPS;
    }

    /**
     * @notice Calculates what percentage one value is of another in basis points
     * @param part The part value
     * @param whole The whole value
     * @return The percentage in basis points
     */
    function toBps(uint256 part, uint256 whole) internal pure returns (uint256) {
        if (whole == 0) return 0;
        return (part * MAX_BPS) / whole;
    }

    /**
     * @notice WAD multiplication
     * @param a First value
     * @param b Second value (in WAD)
     * @return The result
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / WAD;
    }

    /**
     * @notice WAD division
     * @param a Numerator
     * @param b Denominator (in WAD)
     * @return The result
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "MathUtils: division by zero");
        return (a * WAD) / b;
    }

    /**
     * @notice Returns the minimum of two values
     * @param a First value
     * @param b Second value
     * @return The minimum
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Returns the maximum of two values
     * @param a First value
     * @param b Second value
     * @return The maximum
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice Calculates average of two values
     * @param a First value
     * @param b Second value
     * @return The average
     */
    function avg(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @notice Safe subtraction that returns 0 if result would be negative
     * @param a Minuend
     * @param b Subtrahend
     * @return The result or 0
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}
