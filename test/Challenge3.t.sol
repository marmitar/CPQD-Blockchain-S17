// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import { sqrt } from "prb-math/Common.sol";

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
     * @notice Maximum gas used by {SQRT}.
     */
    uint16 private constant GAS_LIMIT = 498;

    /**
     * @notice Calculates the square root of `x`, returning its integer part.
     */
    function iSqrt(uint256 x) private noGasMetering returns (uint256 root) {
        root = run(GAS_LIMIT, SQRT, abi.encode(x)).asUint256();
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_SqrtExample() external {
        assertEq(iSqrt(5), 2, "sqrt(5)");
    }

    /**
     * @notice Selected corner cases.
     */
    function test_SqrtSelectedCases() external {
        assertEq(iSqrt(0), 0, "sqrt(0)");
        assertEq(iSqrt(1), 1, "sqrt(1)");
        assertEq(iSqrt(10), 3, "sqrt(10)");
        assertEq(iSqrt(99), 9, "sqrt(99)");
        assertEq(iSqrt(100), 10, "sqrt(100)");
        assertEq(iSqrt(101), 10, "sqrt(101)");
    }

    /**
     * @notice Casacading effect of square root on powers of two.
     */
    function test_SqrtPowersOfTwo() external {
        uint256 UINT8_MAX = type(uint8).max;
        uint256 UINT16_MAX = type(uint16).max;
        uint256 UINT32_MAX = type(uint32).max;
        uint256 UINT64_MAX = type(uint64).max;
        uint256 UINT128_MAX = type(uint128).max;
        uint256 UINT256_MAX = type(uint256).max;

        assertEq(iSqrt(UINT16_MAX), UINT8_MAX, "sqrt(UINT16_MAX)");
        assertEq(iSqrt(UINT16_MAX + 1), UINT8_MAX + 1, "sqrt(UINT16_MAX + 1)");
        assertEq(iSqrt(UINT32_MAX), UINT16_MAX, "sqrt(UINT32_MAX)");
        assertEq(iSqrt(UINT32_MAX + 1), UINT16_MAX + 1, "sqrt(UINT32_MAX + 1)");
        assertEq(iSqrt(UINT64_MAX), UINT32_MAX, "sqrt(UINT64_MAX)");
        assertEq(iSqrt(UINT64_MAX + 1), UINT32_MAX + 1, "sqrt(UINT64_MAX + 1)");
        assertEq(iSqrt(UINT128_MAX), UINT64_MAX, "sqrt(UINT128_MAX)");
        assertEq(iSqrt(UINT128_MAX + 1), UINT64_MAX + 1, "sqrt(UINT128_MAX + 1)");
        assertEq(iSqrt(UINT256_MAX), UINT128_MAX, "sqrt(UINT256_MAX)");
    }

    /**
     * @notice Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_Sqrt(uint256 x) external {
        assertEq(iSqrt(x), sqrt(x), "sqrt(0 <= x <= UINT256_MAX)");
    }

    /**
     * Shuffle fuzzer input so large values are favored.
     */
    function shuffleUint256(uint256 value) private noGasMetering returns (uint256 shuffled) {
        return uint256(keccak256(abi.encode(value)));
    }

    /**
     * @notice Fuzz testing, focused on very large numbers.
     */
    function testFuzz_SqrtBig(uint256 input) external {
        uint256 x = shuffleUint256(input);
        assertEq(iSqrt(x), sqrt(x), "sqrt(0 <= x <= UINT256_MAX)");
    }
}
