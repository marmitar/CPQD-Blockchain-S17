// SPDX-License-Identifier: GPL-2.0-only
// Gas efficient SQRT method, computes floor(sqrt(x)).
// Constant gas cost of 339.
//
// Authors: Lohann Ferreira, Tiago de Paula
pragma solidity >=0.7.0 <0.9.0;

function sqrt(uint256 x) pure returns (uint256 r) {
    assembly ("memory-safe") {
        // r ≈ log2(x)
        r := shl(7, lt(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, x))
        r := or(r, shl(6, lt(0xFFFFFFFFFFFFFFFF, shr(r, x))))
        r := or(r, shl(5, lt(0xFFFFFFFF, shr(r, x))))
        r := or(r, shl(4, lt(0xFFFF, shr(r, x))))
        r := or(r, shl(3, lt(0xFF, shr(r, x))))

        let lut := 0x1B3647545F69737B838B9299A0A6ACB2B7BDC2C8CDD2D6DBE0E4E9EDF1F6FAFE
        let i := shr(3, shr(r, x))
        r := shr(4, shl(shr(1, r), byte(i, lut)))

        // Newton's method
        r := shr(1, add(r, div(x, r)))
        r := shr(1, add(r, div(x, r)))
        r := shr(1, add(r, div(x, r)))
        r := shr(1, add(r, div(x, r)))
        r := shr(1, add(r, div(x, r)))
        r := shr(1, add(r, div(x, r)))

        // r = min(r, x/r)
        r := sub(r, gt(r, div(x, r)))
    }
}
