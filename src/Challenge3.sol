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

        // At this point, our $\log_2(x)$ has the 5 upper bits right. For the remaining bits, uses can a lookup table
        // based on a De Bruijn sequence to improve our approximation.
        //
        // For 3 bits in log space we would need 8 bits of input, so a 256 byte table. We can actually skip the last
        // bit, because we'll just use $log_2(x) / 2$, not the full $\log_2(x)$. The last bit of $\log_2(x)$ represents
        //  2 bits in $x$, so our table is reduced to the following 64 bytes:
        // 0x00020202040404040404040404040404060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606
        //
        // This still doesn't fit in 32 bytes, but we can abuse the redundancy in the table to reach the last values.
        // Specifically, 0x06 appears on all bytes from position 16 to 63, which means that it is accessed whenever the
        // index matches 0x170. In this case, an index $i$ smaller than 31 can be used directly, but an index of 32-63
        // more can be reduced to $i >> 1$, which maps to 16-31 and gives the same result 0x06. This can be expressed
        // as $i >> (i > 31)$ or equivalently as $i >> (i >> 5)$.
        let table := 0x02020204040404040404040404040406060606060606060606060606060606

        let i := shr(2, shr(log, x))
        i := shr(shr(5, i), i)
        log := or(log, byte(i, table))

        // Here we have an value almost equal to $\log_2(x)$, except maybe for the last bit. This is not an issue,
        // because we'll use $2^{\log_2(x)/2} \approx \sqrt{x}$ as an initial approximation for the square root.
        // This value ensures that:
        // \[ 2^{\log_2(x)/2} \leq \sqrt{x} < 2^{\log_2(x)/2 + 1} \]
        // So at least the first bit is correct.
        root := shl(shr(1, log), 1)

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
