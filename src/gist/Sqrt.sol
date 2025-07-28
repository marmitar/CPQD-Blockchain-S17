// SPDX-License-Identifier: GPL-2.0-only
// Gas efficient SQRT method, computes floor(sqrt(x)).
// Constant gas cost of 341.
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

        let lut := 0x02030405060707080809090A0A0A0B0B0B0C0C0C0D0D0D0E0E0E0F0F0F0F1010
        let i := shr(3, shr(r, x))
        r := shl(shr(1, r), byte(i, lut))

        // Newton's method
        r := shr(1, add(r, div(x, r)))
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
