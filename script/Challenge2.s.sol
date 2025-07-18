// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Script, console } from "forge-std/Script.sol";

/**
 * @title Calculate approximate fractions of $pi$.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Run with `forge script script/Challenge2.s.sol:PiFractionScript`.
 */
contract PiFractionScript is Script {
    /**
     * @notice Check if `a * p1 + p0` overflows.
     */
    function overflows(uint256 a, uint256 p0, uint256 p1) private pure returns (bool) {
        unchecked {
            return p1 > 0 && a > (type(uint256).max - p0) / p1;
        }
    }

    /**
     * @notice Find the closest approximation with odd `denominator` using of a real number
     * [Diophantine's method](https://en.wikipedia.org/wiki/Diophantine_approximation).
     * @param maxNumerator Assumed to be `2**256` if zero.
     */
    function diophantineApprox(uint16[] memory coef, uint256 maxNumerator)
        private
        pure
        returns (uint256 numerator, uint256 denominator)
    {
        unchecked {
            (uint256 p, uint256 q) = (maxNumerator, 1);

            (uint256 p0, uint256 p1, uint256 q0, uint256 q1) = (0, 1, 1, 0);
            for (uint256 i = 0; i < coef.length; i++) {
                uint256 a = coef[i];

                if (overflows(a, p0, p1) || overflows(a, q0, q1) || maxNumerator > 0 && p1 > maxNumerator) {
                    console.log("Maximum numerator reached after", i + 1, "iterations");
                    return (p, q);
                }

                (p0, p1) = (p1, a * p1 + p0);
                (q0, q1) = (q1, a * q1 + q0);
                if (q1 % 2 == 1) {
                    (p, q) = (p1, q1);
                }
            }

            console.log("Maximum numerator was not reached after the first", coef.length, "coefficients of A001203");
            return (p, q);
        }
    }

    /**
     * @notice Simple continued fraction expansion of Pi.
     * @dev See <https://oeis.org/A001203>.
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
     * @notice Find the closest approximation of pi with odd `denominator` up to `maxNumerator`.  `2**256`.
     */
    function piFraction(uint256 maxNumerator) private view returns (uint256 numerator, uint256 denominator) {
        console.log("Finding best fractional approximation of pi up to 2**256");
        return diophantineApprox(coefPi, maxNumerator);
    }

    /**
     * @notice Find the multiplicative inverse of `x` modulo `2**256`. That is, `x * y == 1 (mod 2**256)`.
     * @dev Based on <https://stackoverflow.com/a/70501399/7182981>.
     */
    function modularInverse(uint256 x) private pure returns (uint256 y) {
        // modular arithmetic
        unchecked {
            uint256 max = type(uint256).max;

            /* Initialization: */
            // (r0, r1) = (x, 2**256);
            // (s0, s1) = (1, 0);

            /* First iteration: */
            // q = r0 / r1 = x / 2**256 = 0;
            // (r0, r1) = (r1, r0 - q * r1) = (2**256, x);
            // (s0, s1) = (s1, s0 + q * s1) = (0, 1);

            /* Second iteration: */
            // q = r0 / r1 = 2**256 / x;
            uint256 q2 = max / x + (max % x + 1) / x;
            // (r0, r1) = (r1, r0 - q * r1) = (x, 2**256 - q * x);
            (uint256 r0, uint256 r1) = (x, (~((q2 - 1) * x) + 1) - x);
            // (s0, s1) = (s1, s0 + q * s1) = (1, q);
            (uint256 s0, uint256 s1) = (1, q2);
            // (t0, t1) = (t1, t0 + q * t1) = (0, q);

            uint256 n = 2;
            while (r1 > 0) {
                uint256 q = r0 / r1;
                (r0, r1) = (r1, (r0 > q * r1) ? r0 - q * r1 : q * r1 - r0);
                (s0, s1) = (s1, s0 + q * s1);
                n += 1;
            }

            // gcd = r0
            if (n % 2 == 1) {
                s0 = ~s0 + 1;
            }
            // else { t0 = a - t0; }

            require(r0 == 1, "x is not invertible for uint256");
            // r0 = x * s0 + 2**256 * t0 = 1    =>    x * s == 1 (mod 2**256)
            return s0;
        }
    }

    /**
     * @dev Maximum input for the radius specified in Challenge 2.
     */
    uint256 constant MAX_R = 65_535;

    /**
     * @notice Find closest approximation of pi and its inverse modulo `2^256`.
     */
    function run()
        external
        view
        returns (bytes32 numerator, bytes32 denominator, bytes32 denominatorInverse, bytes32 offset)
    {
        uint256 safeNumerator = type(uint256).max / (MAX_R * MAX_R);
        (uint256 p, uint256 q) = piFraction(safeNumerator);
        uint256 qInv = modularInverse(q);
        return (bytes32(p), bytes32(q), bytes32(qInv), bytes32(q / 2));
    }
}
