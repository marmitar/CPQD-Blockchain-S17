// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

/**
 * @notice Calculate the integer approximation for area the of a circle of radius `r`.
 * @param r Radius in range [0, 65_535]. A larger input will result in overflow and return garbage.
 */
function circleArea(uint256 r) pure returns (uint256 area) {
    assembly ("memory-safe") {
        // Q: denominator of the chosen π approximation
        let q := 0x517cc1b71c3a5ba1556b0bd08a4ba0b4170db1198f6a24e9d36ffaac
        // Q/2
        let qh := 0x28be60db8e1d2dd0aab585e84525d05a0b86d88cc7b51274e9b7fd56
        // P: numerator of the π fraction
        let p := 0xffffffffddbdaafcf520c2a336649a78c8758a48aa801b09f3770572
        /// Here P/Q ≈ π. The values were selected so that `circleArea(65_535 + 1)` overflows.

        // do: A = (P × r² + Q/2) / Q
        area := div(add(mul(p, mul(r, r)), qh), q)
    }
}
