// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

/**
 * @notice Calculate the integer square root of `x`.
 * @dev Based on <https://github.com/PaulRBerg/prb-math/blob/v4.1.0/src/Common.sol#L587-L675>.
 */
function sqrt(uint256 x) pure returns (uint256 root) {
    assembly ("memory-safe") {
        // Find the most significant bit, equivalent to `log2(x)`.
        let xAux := x
        // msb7 = (x >= 2**128) ? 128 : 0
        let msb7 := shl(7, gt(xAux, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        xAux := shr(msb7, xAux) // x >> msb7
        // msb6 = (x >= 2**64) ? 64 : 0
        let msb6 := shl(6, gt(xAux, 0xFFFFFFFFFFFFFFFF))
        xAux := shr(msb6, xAux) // x >> msb6
        // msb5 = (x >= 2**32) ? 32 : 0
        let msb5 := shl(5, gt(xAux, 0xFFFFFFFF))
        xAux := shr(msb5, xAux) // x >> msb5
        // msb4 = (x >= 2**16) ? 16 : 0
        let msb4 := shl(4, gt(xAux, 0xFFFF))
        xAux := shr(msb4, xAux) // x >> msb4
        // msb3 = (x >= 2**8) ? 8 : 0
        let msb3 := shl(3, gt(xAux, 0xFF))
        xAux := shr(msb3, xAux) // x >> msb3
        // msb2 = (x >= 2**4) ? 4 : 0
        let msb2 := shl(2, gt(xAux, 0xF))
        xAux := shr(msb2, xAux) // x >> msb2
        // msb1 = (x >= 2**2) ? 2 : 0
        let msb1 := shl(1, gt(xAux, 0x3))
        // SKIPPED: x >> msb1
        // SKIPPED: msb0 = (x >= 2**1) ? 1 : 0
        // msb = msb1 | msb2 | msb3 | msb4 | msb5 | msb6 | msb7
        let msb := or(or(or(or(or(or(msb1, msb2), msb3), msb4), msb5), msb6), msb7)

        // Get the closest power of two: $x_0 = 2^{\lfloor \log_2(x) / 2 \rfloor}$.
        // This will be our initial guess for Newton's method, which has at least one bit correct.
        root := shl(shr(1, msb), 1)
        // Now we have 1 bit correct of $\sqrt{x}$. The next 7 iterations of Newton's method will expand it into 256
        // bits.
        // Note: division by zero returns 0, so not an issue here.
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        // For almost perfect squares, Newton's method cycles between `⌊√x⌋` => `⌊√x⌋ + 1`, so we need to
        // round the result down.
        root := sub(root, gt(root, div(x, root)))
    }
}
