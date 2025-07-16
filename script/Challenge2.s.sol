// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Script, console } from "forge-std/Script.sol";

/**
 * @title Calculate approximate fractions of $pi$.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Run with `forge script script/Challenge2.s.sol:PiFractionScript`.
 */
contract PiFractionScript is Script {
    /**
     * @dev Simple continued fraction expansion of Pi. See <https://oeis.org/A001203>.
     */
    /// forgefmt: disable-next-item
    uint16[] private coefPi = [
        3, 7, 15, 1, 292, 1, 1, 1, 2, 1, 3, 1, 14, 2, 1, 1, 2, 2, 2, 2, 1, 84, 2, 1, 1, 15, 3, 13, 1, 4, 2, 6, 6, 99, 1,
        2, 2, 6, 3, 5, 1, 1, 6, 8, 1, 7, 1, 2, 3, 7, 1, 2, 1, 1, 12, 1, 1, 1, 3, 1, 1, 8, 1, 1, 2, 1, 6, 1, 1, 5, 2, 2,
        3, 1, 2, 4, 4, 16, 1, 161, 45, 1, 22, 1, 2, 2, 1, 4, 1, 2, 24, 1, 2, 1, 3, 1, 2, 1, 1, 10, 2, 5, 4, 1, 2, 2, 8,
        1, 5, 2, 2, 26, 1, 4, 1, 1, 8, 2, 42, 2, 1, 7, 3, 3, 1, 1, 7, 2, 4, 9, 7, 2, 3, 1, 57, 1, 18, 1, 9, 19, 1, 2,
        18, 1, 3, 7, 30, 1, 1, 1, 3, 3, 3, 1, 2, 8, 1, 1, 2, 1, 15, 1, 2, 13, 1, 2, 1, 4, 1, 12, 1, 1, 3, 3, 28, 1, 10
    ];

    /**
     * @notice Find the closest approximation of pi up to `maxNumerator` using
     * [Diophantine's method](https://en.wikipedia.org/wiki/Diophantine_approximation).
     */
    function piFraction(uint256 maxNumerator) private view returns (uint256 numerator, uint256 denominator) {
        console.log("Finding best fractional approximation of pi up to", maxNumerator);

        if (maxNumerator < 3) {
            console.log("Numerator too low, using closest integer");
            return (maxNumerator, 1);
        }

        (uint256 p0, uint256 p1, uint256 q0, uint256 q1) = (0, 1, 1, 0);
        for (uint256 i = 0; i < coefPi.length; i++) {
            uint256 a = coefPi[i];

            (p0, p1) = (p1, a * p1 + p0);
            (q0, q1) = (q1, a * q1 + q0);
            if (p1 > maxNumerator) {
                console.log("Maximum numerator reached after", i + 1, "iterations");
                return (p0, q0);
            }
        }

        console.log("Maximum numerator was not reached after the first", coefPi.length, "coefficients of A001203");
        return (p1, q1);
    }

    /**
     * @dev Maximum input for the radius specified in Challenge 2.
     */
    uint256 constant MAX_R = 65_535;

    /**
     * @notice Find closest approximation of pi that is guaranteed to not overflow on multiplication.
     */
    function run() external view returns (bytes32 numerator, bytes32 denominator, bytes32 offset) {
        uint256 safeNumerator = type(uint256).max / (MAX_R * MAX_R);
        (uint256 p, uint256 q) = piFraction(safeNumerator);
        return (bytes32(p), bytes32(q), bytes32(q / 2));
    }
}
