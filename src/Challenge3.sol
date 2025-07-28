// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

/**
 * @notice Efficient Integer Square Root method.
 * @dev Based on <https://gist.github.com/Lohann/f01e2558691ba8648f1e5a7c6e8d37da>.
 */
function sqrt(uint256 x) pure returns (uint256 root) {
    assembly ("memory-safe") {
        // First, we find an approximation for $\log_2(x)$.
        //
        // The following algorithm does a "binary seach" over the regions of $x$, updating our approximation of
        // $\log_2(x)$ depending on wether the current value is bigger or lower than threshold (i.e. the highest bit is
        // left or right of a specific region). At each iteration, it gives one extra bit of information on the result
        // of $\log_2(x)$.
        let log := shl(7, lt(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, x))
        log := or(log, shl(6, lt(0xffffffffffffffff, shr(log, x))))
        log := or(log, shl(5, lt(0xffffffff, shr(log, x))))
        log := or(log, shl(4, lt(0xffff, shr(log, x))))
        log := or(log, shl(3, lt(0xff, shr(log, x))))

        // At this point, our $\log_2(x)$ has the 5 upper bits right, so $k = x >> \log_2(x)$ is a number between 0 and
        // 255. We'll use a De Bruijn sequence to approximate the square root of $k$, and then do:
        // \[ \sqrt{x} = \sqrt{k} \times 2^{\log_2(x) / 2} \]
        //
        // Since the EVM can only index 32 in the stack, we'll use the upper 5 bits of $k$ for indexing.
        let table := 0x02030405060707080809090a0a0a0b0b0b0c0c0c0d0d0d0e0e0e0f0f0f0f1010
        root := byte(shr(3, shr(log, x)), table)

        // Here we approximate $\sqrt{x} = \sqrt{k} \times 2^{\log_2(x) / 2}$, which is at least 1 bit correct. It
        // should be more, but we had to throw some information away.
        root := mul(root, shl(shr(1, log), 1))

        // Now we have 1 bit correct of $\sqrt{x}$, and we need 128 bits for the roots of all `uint256` numbers. Each
        // iteration of the Newton's method doubles the precision, so 7 iterations are required.
        // Note: division by zero returns 0, giving the correct result for $\sqrt{0}$.
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        root := shr(1, add(root, div(x, root)))
        // For almost perfect squares, Newton's method cycles between ⌊√x⌋ and ⌊√x⌋ + 1, so we need to
        // round the result down.
        root := sub(root, gt(root, div(x, root)))
    }
}
