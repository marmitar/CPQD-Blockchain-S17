// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import { sqrt } from "prb-math/Common.sol";

import { SqrtGasUsage } from "../script/Challenge3.s.sol";
import { Assembler, Decode, Runnable, RuntimeContract } from "./Assembler.sol";

using Runnable for RuntimeContract;
using Decode for bytes;

/**
 * @title Unit tests for the Integer Square Root contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge3Test is Assembler, Test {
    /**
     * @notice Integer Square Root contract, done in EVM bytecode.
     */
    RuntimeContract private immutable SQRT = assemble("src/Challenge3.evm");

    /**
     * @notice Verify distributed assembly.
     */
    function test_SqrtAssembly() external {
        RuntimeContract distributed = load("dist/SQRT.hex");
        assertEq(SQRT.code(), distributed.code(), "distributed code");
    }

    /**
     * @notice Functions to estimate gas usage of {SQRT}.
     */
    SqrtGasUsage private immutable ESTIMATOR = new SqrtGasUsage();

    /**
     * @notice Maximum gas used by {SQRT}.
     */
    uint16 private constant GAS_LIMIT = 498;

    /**
     * @notice Calculates the square root of `x`, returning its integer part.
     */
    function iSqrt(uint256 x) private noGasMetering returns (uint256 root) {
        root = run(GAS_LIMIT, SQRT, abi.encode(x)).asUint256();
        uint256 gasUsed = lastCallGas.gasTotalUsed;
        assertLe(ESTIMATOR.gasDiff(x, gasUsed), 2, "gasDiff");
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_SqrtExample() external {
        assertEq(iSqrt(5), 2, "sqrt(5)");
        assertGasUsed(GAS_LIMIT, 390);
    }

    /**
     * @notice Selected corner cases.
     */
    function test_SqrtSelectedCases() external {
        assertEq(iSqrt(0), 0, "sqrt(0)");
        assertGasUsed(GAS_LIMIT, 38);
        assertEq(iSqrt(1), 1, "sqrt(1)");
        assertGasUsed(GAS_LIMIT, 384);
        assertEq(iSqrt(10), 3, "sqrt(10)");
        assertGasUsed(GAS_LIMIT, 390);
        assertEq(iSqrt(99), 9, "sqrt(99)");
        assertGasUsed(GAS_LIMIT, 408);
        assertEq(iSqrt(100), 10, "sqrt(100)");
        assertGasUsed(GAS_LIMIT, 408);
        assertEq(iSqrt(101), 10, "sqrt(101)");
        assertGasUsed(GAS_LIMIT, 408);
    }

    /**
     * @notice Casacading effect of square root on powers of two.
     */
    function test_SqrtPowersOfTwo() external {
        assertEq(iSqrt(2 ** 2 - 1), 2 ** 1 - 1, "sqrt(2**2-1)");
        assertGasUsed(GAS_LIMIT, 384);
        assertEq(iSqrt(2 ** 2), 2 ** 1, "sqrt(2**2)");
        assertGasUsed(GAS_LIMIT, 390);
        assertEq(iSqrt(2 ** 4 - 1), 2 ** 2 - 1, "sqrt(2**4-1)");
        assertGasUsed(GAS_LIMIT, 390);
        assertEq(iSqrt(2 ** 4), 2 ** 2, "sqrt(2**4)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 8 - 1), 2 ** 4 - 1, "sqrt(2**8-1)");
        assertGasUsed(GAS_LIMIT, 405);
        assertEq(iSqrt(2 ** 8), 2 ** 4, "sqrt(2**8)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 16 - 1), 2 ** 8 - 1, "sqrt(2**16-1)");
        assertGasUsed(GAS_LIMIT, 426);
        assertEq(iSqrt(2 ** 16), 2 ** 8, "sqrt(2**16)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 32 - 1), 2 ** 16 - 1, "sqrt(2**32-1)");
        assertGasUsed(GAS_LIMIT, 441);
        assertEq(iSqrt(2 ** 32), 2 ** 16, "sqrt(2**32)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 64 - 1), 2 ** 32 - 1, "sqrt(2**64-1)");
        assertGasUsed(GAS_LIMIT, 462);
        assertEq(iSqrt(2 ** 64), 2 ** 32, "sqrt(2**64)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 128 - 1), 2 ** 64 - 1, "sqrt(2**128-1)");
        assertGasUsed(GAS_LIMIT, 477);
        assertEq(iSqrt(2 ** 128), 2 ** 64, "sqrt(2**128)");
        assertGasUsed(GAS_LIMIT, 402);
        assertEq(iSqrt(2 ** 256 - 1), 2 ** 128 - 1, "sqrt(2**256-1)");
        assertGasUsed(GAS_LIMIT, 498);
    }

    /**
     * @notice Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_Sqrt(uint256 x) external {
        assertEq(iSqrt(x), sqrt(x), "sqrt(0 <= x <= 2**256 - 1)");
    }

    /**
     * @notice Shuffle fuzzer input so large values are favored.
     */
    function shuffleUint256(uint256 value) private noGasMetering returns (uint256 shuffled) {
        return uint256(keccak256(abi.encode(value)));
    }

    /**
     * @notice Fuzz testing, focused on very large numbers.
     */
    function testFuzz_SqrtBig(uint256 input) external {
        uint256 x = shuffleUint256(input);
        assertEq(iSqrt(x), sqrt(x), "sqrt(0 <= x <= 2**256 - 1)");
    }
}
