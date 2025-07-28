// SPDX-License-Identifier: GPL-2.0
// Gas efficient SQRT method, computes floor(sqrt(x)).
// Constant gas cost of 407 + solidity overhead.
// 
// Author: Lohann Ferreira
pragma solidity >=0.7.0 <0.9.0;

contract Sqrt {
    function sqrt(uint256 x) public pure returns (uint256 r) {
        assembly ("memory-safe") {
            // r = floor(log2(x))
            r := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            let xx := shr(r, x)

            let rr := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
            xx := shr(rr, xx)
            r := or(r, rr)

            rr := shl(5, gt(xx, 0xFFFFFFFF))
            xx := shr(rr, xx)
            r := or(r, rr)

            rr := shl(4, gt(xx, 0xFFFF))
            xx := shr(rr, xx)
            r := or(r, rr)

            rr := shl(3, gt(xx, 0xFF))
            xx := shr(rr, xx)
            r := or(r, rr)

            rr := shl(2, gt(xx, 0x0F))
            xx := shr(rr, xx)
            r := or(r, rr)

            rr := shl(1, gt(xx, 0x03))
            xx := shr(rr, xx)
            r := or(r, rr)
            
            r := shl(shr(1, r), 1)
            
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
}