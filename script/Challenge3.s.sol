// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Script, VmSafe, console } from "forge-std/Script.sol";
import { sqrt } from "prb-math/Common.sol";
import { SD59x18, sd } from "prb-math/SD59x18.sol";
import { HALF_UNIT, UD60x18, UNIT, ZERO, convert, ud } from "prb-math/UD60x18.sol";

import { Assembler, Decode, Runnable, RuntimeContract } from "../test/Assembler.sol";

using Runnable for RuntimeContract;
using Decode for bytes;

/**
 * @title Estimate gas usage for the SQRT bytecode.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Run with `forge script script/Challenge3.s.sol:SqrtGasUsage`.
 */
contract SqrtGasUsage is Script {
    // forgefmt: disable-start
    /** @notice Gas used for the first instructions of {SQRT}. */
    uint256 private constant HEADER = 2e18 + 4 * 3e18 + 10e18;
    /** @notice Gas used for algorithm initialization, `result` and `xAux`. */
    uint256 private constant INIT = 2 * 3e18;
    /** @notice Gas used for comparison in the unrolled loop for `log2(x)`. */
    uint256 private constant SHIFT_CMP = 4 * 3e18 + 10e18 + 1e18;
    /** @notice Gas used for the branch taken body of `log2(x)`. */
    uint256 private constant SHIFT_TAKEN = 6 * 3e18;
    /** @notice Gas used for the very last branch taken of `log2(x)`. */
    uint256 private constant SHIFT_LAST = 2 * 3e18;
    /** @notice Gas used for one iteration of the unrolled loop for Newton-Raphson's method. */
    uint256 private constant NEWTON_STEP = 5 * 3e18 + 5e18;
    /** @notice Gas used for finalization of Newton-Raphson's method. */
    uint256 private constant NEWTON_FIN = 4 * 3e18;
    /** @notice Gas used for the last instructions of {SQRT}. */
    uint256 private constant RETURN = 1e18 + 3e18 + 6e18 + 2 * 2e18;
    // forgefmt: disable-end

    /**
     * @notice Describe the expected distributions for each branch of {SQRT}.
     */
    struct InputDistribution {
        /**
         * @notice Probability that `x` is not zero.
         */
        UD60x18 notZero;
        /**
         * @notice Probability for each group of bits that trigger each branch in `log2(x)`.
         */
        UD60x18[7] bitSets;
    }

    /**
     * @notice Estimate gas used by the {SQRT} EVM contract for the given `input` distribution.
     */
    function estimatedGasUsageFor(InputDistribution memory input) private pure returns (UD60x18 expected) {
        UD60x18 gasNonZero = ud(INIT);

        gasNonZero = gasNonZero + ud(SHIFT_CMP) + input.bitSets[0] * ud(SHIFT_LAST);
        for (uint8 i = 1; i < 7; i++) {
            gasNonZero = gasNonZero + ud(SHIFT_CMP) + input.bitSets[i] * ud(SHIFT_TAKEN);
        }

        gasNonZero = gasNonZero + ud(8e18) * ud(NEWTON_STEP) + ud(NEWTON_FIN);

        return ud(HEADER) + input.notZero * gasNonZero + ud(RETURN);
    }

    /**
     * @notice Calculates `x / 2**256`, for probability calculations.
     */
    function inv256(uint256 x) private pure returns (UD60x18) {
        // x / 2**256 = 2**(log2(x / 2**256)) = 2**(log2(x) - 256)
        SD59x18 logx = convert(x).log2().intoSD59x18();
        return sd(2e18).pow(logx - sd(256e18)).intoUD60x18();
    }

    /**
     * @notice Average distribution for each branch in the bytecode, assuming uniformily distributed `x`.
     */
    function averageDistribution() private pure returns (InputDistribution memory dist) {
        UD60x18 pZero = inv256(1); // 1/2**256
        UD60x18 pBitSet = HALF_UNIT;

        return InputDistribution({
            notZero: UNIT - pZero,
            bitSets: [pBitSet, pBitSet, pBitSet, pBitSet, pBitSet, pBitSet, pBitSet]
        });
    }

    /**
     * @notice Estimate the average amount of gas used in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasAverage() public pure returns (UD60x18 mean) {
        return estimatedGasUsageFor(averageDistribution());
    }

    /**
     * @notice Calculate the variance of two independent Bernoulli distributions.
     */
    function combinedVariance(UD60x18 p, UD60x18 q) private pure returns (UD60x18 variance) {
        UD60x18 pq = p * q;
        return pq - pq.powu(2);
    }

    /**
     * @notice Estimate the variance of gas usage in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasVariance() public pure returns (UD60x18 variance) {
        InputDistribution memory dist = averageDistribution();
        UD60x18 pNotZero = dist.notZero;

        // covariance ignored as it is too small to be representable with UD60x18
        variance = combinedVariance(pNotZero, dist.bitSets[0]) * ud(SHIFT_LAST).powu(2);
        for (uint8 i = 1; i < 7; i++) {
            variance = variance + combinedVariance(pNotZero, dist.bitSets[i]) * ud(SHIFT_TAKEN).powu(2);
        }
    }

    /**
     * @notice Estimate the standard deviation of gas usage in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasStdDev() public pure returns (UD60x18 std) {
        return gasVariance().sqrt();
    }

    /**
     * @notice String representation of a {UD60x18} decimal.
     */
    function toString(UD60x18 value) private pure returns (string memory str) {
        uint256 integer = convert(value);
        uint256 decimal = value.frac().intoUint256();

        string memory left = vm.toString(integer);
        bytes memory right = bytes(vm.toString(decimal));

        for (uint256 i = right.length; i > 0; i--) {
            if (right[i - 1] == "0") {
                right[i - 1] = " ";
            } else {
                break;
            }
        }
        return string.concat(left, ".", vm.trim(string(right)));
    }

    /**
     * @notice Calculate which groups of bits are set in `x`, for finding `log2(x)`.
     */
    function bitSetsOf(uint256 x) private pure returns (bool[7] memory bitSets) {
        for (uint8 i = 7; i > 0; i--) {
            uint8 p = uint8(2 ** i);
            if (x >= 2 ** p) {
                x >>= p;
                bitSets[i - 1] = true;
            } else {
                bitSets[i - 1] = false;
            }
        }
    }

    /**
     * @notice Condense a boolean value into a Bernoulli distribution (i.e., either `p = 0.0` or `p = 1.0`).
     */
    function d(bool set) private pure returns (UD60x18 condensedDistribution) {
        return set ? UNIT : ZERO;
    }

    /**
     * @notice Find the distribution of each descriptor of `x`. It will be either one or zero for each value.
     */
    function inputDistributionOf(uint256 x) public pure returns (InputDistribution memory dist) {
        bool[7] memory bs = bitSetsOf(x);

        return InputDistribution({
            notZero: d(x != 0),
            bitSets: [d(bs[0]), d(bs[1]), d(bs[2]), d(bs[3]), d(bs[4]), d(bs[5]), d(bs[6])]
        });
    }

    /**
     * @notice Expected gas used by the {SQRT} EVM contract for the input `x`.
     */
    function gasUsage(uint256 x) public pure returns (UD60x18 gas) {
        return estimatedGasUsageFor(inputDistributionOf(x));
    }

    /**
     * @notice Integer Square Root contract, done in EVM bytecode.
     */
    RuntimeContract private immutable SQRT = new Assembler().assemble("src/Challenge3.evm");

    /**
     * @notice Get the absolute difference between estimated and measured gas usage. Rounded away from zero.
     */
    function gasDiff(uint256 x, uint256 gasUsed) external pure returns (uint256) {
        UD60x18 expected = estimatedGasUsageFor(inputDistributionOf(x));
        UD60x18 used = convert(gasUsed);
        UD60x18 diff = expected > used ? expected - used : used - expected;
        return convert(diff.ceil());
    }

    /**
     * @notice Measure gas usage for {SQRT} with input `x`.
     */
    function measure(uint256 x) private view returns (uint256 gasUsed) {
        (, VmSafe.Gas memory usage) = SQRT.staticCall(500, vm, abi.encode(x));
        return usage.gasTotalUsed;
    }

    /**
     * @notice Generates evenly distributed values using a seed and an index.
     */
    function prngKeccak256(uint256 seed, uint256 index) private pure returns (uint256 random) {
        unchecked {
            // wrapping math
            return uint256(keccak256(abi.encode(seed, index)));
        }
    }

    /**
     * @notice Compare the estimated and measured gas usage for input `x` and log results to the console.
     */
    function test(uint256 x) private view {
        UD60x18 expected = estimatedGasUsageFor(inputDistributionOf(x));
        uint256 used = measure(x);
        UD60x18 fUsed = convert(used);
        string memory ord = (fUsed > expected) ? " > " : (fUsed < expected) ? " < " : " = ";

        string memory message = string.concat(vm.toString(x), ": ", toString(expected), ord, vm.toString(used));
        console.log(message);
    }

    /**
     * @notice Compare the estimated and measured gas usage for all values `x` such that `x + 1` is a perfect square.
     * These values are special because the Newton's method doesn't fully coverge for them.
     */
    function testPerfectSquares(uint256 max) private view {
        uint256 stop = sqrt(max) + 1;
        for (uint256 i = 1; i < stop; i++) {
            test(i * i - 1);
        }
    }

    /**
     * @notice Estimate the distribution of gas usage for {SQRT}.
     */
    function run() external view returns (string memory mean, string memory stdDev) {
        testPerfectSquares(1000);

        mean = toString(gasAverage());
        stdDev = toString(gasStdDev());
    }
}
