// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Assembler, Runnable, RuntimeContract } from "./Assembler.sol";
import { Test } from "forge-std/Test.sol";
import { sqrt } from "prb-math/Common.sol";

using Runnable for RuntimeContract;

/**
 * @title Unit tests for the Integer Square Root contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge3Test is Assembler, Test {
    /**
     * @dev Integer Square Root contract, done in EVM bytecode.
     */
    RuntimeContract private immutable SQRT = assemble("src/Challenge3.evm");

    /**
     * @notice Verify distributed assembly.
     */
    function test_SqrtAssembly() external {
        RuntimeContract distributed = load("dist/SQRT.hex");
        assertEq(SQRT.code(), distributed.code());
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_SqrtExample() external {
        assertEq(SQRT.run(5), 2);
    }

    /**
     * @notice Selected corner cases.
     */
    function test_SqrtSelectedCases() external {
        assertEq(SQRT.run(0), 0);
        assertEq(SQRT.run(1), 1);
        assertEq(SQRT.run(10), 3);
        assertEq(SQRT.run(99), 9);
        assertEq(SQRT.run(100), 10);
        assertEq(SQRT.run(101), 10);
    }

    /**
     * @notice Casacading effect of square root on powers of two.
     */
    function test_SqrtPowersOfTwo() external {
        assertEq(SQRT.run(type(uint16).max), type(uint8).max);
        assertEq(SQRT.run(type(uint32).max), type(uint16).max);
        assertEq(SQRT.run(type(uint64).max), type(uint32).max);
        assertEq(SQRT.run(type(uint128).max), type(uint64).max);
        assertEq(SQRT.run(type(uint256).max), type(uint128).max);
    }

    /**
     * @notice Precise implementation using `prb-math`.
     */
    function isqrt(uint256 x) private noGasMetering returns (uint256 root) {
        return sqrt(x);
    }

    /**
     * @dev Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_Sqrt(uint256 x) external {
        assertEq(SQRT.run(x), isqrt(x));
    }

    /**
     * Shuffle fuzzer input so large values are favored.
     */
    function shuffleUint256(uint256 value) private noGasMetering returns (uint256 shuffled) {
        return uint256(keccak256(abi.encode(value)));
    }

    /**
     * @dev Fuzz testing, focused on very large numbers.
     */
    function testFuzz_SqrtBig(uint256 input) external {
        uint256 x = shuffleUint256(input);
        assertEq(SQRT.run(x), isqrt(x));
    }
}
