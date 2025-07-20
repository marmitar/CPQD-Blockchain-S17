// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Script, VmSafe, console } from "forge-std/Script.sol";
import { sqrt } from "prb-math/Common.sol";

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
    uint16 private constant HEADER = 2 + 4 * 3 + 10;
    /** @notice Gas used for the first iteration of `log2(x)`. */
    uint16 private constant MSB_FIRST = 8 * 3;
    /** @notice Gas used for comparison in the unrolled loop for `log2(x)`. */
    uint16 private constant MSB_STEP = 10 * 3;
    /** @notice Gas used for the very last iteration of `log2(x)`. */
    uint16 private constant MSB_LAST = 6 * 3;
    /** @notice Initialization of `x0` for Newton's method. */
    uint16 private constant NEWTON_INIT = 5 * 3;
    /** @notice Gas used for one iteration of the unrolled loop for Newton-Raphson's method. */
    uint16 private constant NEWTON_STEP = 5 * 3 + 5;
    /** @notice Gas used for finalization of Newton-Raphson's method. */
    uint16 private constant NEWTON_FIN = 4 * 3;
    /** @notice Gas used for the last instructions of {SQRT}. */
    uint16 private constant RETURN = 1 + 3 + 6 + 2 * 2;
    // forgefmt: disable-end

    /**
     * @notice Estimated gas usage for any `x > 0`.
     */
    uint16 public constant GAS_USAGE =
        HEADER + (MSB_FIRST + 5 * MSB_STEP + MSB_LAST) + (NEWTON_INIT + 8 * NEWTON_STEP + NEWTON_FIN) + RETURN;

    /**
     * @notice Estimated gas usage for `x = 0`.
     */
    uint16 public constant GAS_USAGE_ZERO = HEADER + RETURN;

    /**
     * @notice Estimate the average amount of gas used in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasAverage() public pure returns (uint256 mean) {
        return GAS_USAGE /* (GAS_USAGE_ZERO - GAS_USAGE) / 2**256 */ + 0;
    }

    /**
     * @notice Estimate the variance of gas usage in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasVariance() public pure returns (uint256 variance) {
        return /* 1.24051e-72 */ 0;
    }

    /**
     * @notice Estimate the standard deviation of gas usage in by {SQRT}, assuming uniformily distributed `x`.
     */
    function gasStdDev() public pure returns (uint256 std) {
        return sqrt(gasVariance());
    }

    /**
     * @notice Expected gas used by the {SQRT} EVM contract for the input `x`.
     */
    function gasUsage(uint256 x) public pure returns (uint256 gas) {
        return x == 0 ? GAS_USAGE_ZERO : GAS_USAGE;
    }

    /**
     * @notice Integer Square Root contract, done in EVM bytecode.
     */
    RuntimeContract private immutable SQRT = new Assembler().assemble("src/Challenge3.evm");

    /**
     * @notice Measure gas usage for {SQRT} with input `x`.
     */
    function measure(uint256 x) private view returns (uint256 gasUsed) {
        (, VmSafe.Gas memory usage) = SQRT.staticCall(500, vm, abi.encode(x));
        return usage.gasTotalUsed;
    }

    /**
     * @notice Compare the estimated and measured gas usage for input `x` and log results to the console.
     */
    function test(uint256 x) private view {
        uint256 expected = gasUsage(x);
        uint256 used = measure(x);
        string memory ord = (used > expected) ? " > " : (used < expected) ? " < " : " = ";

        string memory message = string.concat(vm.toString(x), ": ", vm.toString(expected), ord, vm.toString(used));
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
    function run() external view returns (uint256 mean, uint256 stdDev) {
        testPerfectSquares(1000);
        return (gasAverage(), gasStdDev());
    }
}
