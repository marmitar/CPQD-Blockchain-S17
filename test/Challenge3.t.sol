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
    RuntimeContract private challenge3 = load("src/Challenge3.etk");

    /**
     * @dev Execute `challenge3` to find the integer square root of `x`.
     */
    function run(uint256 x) private returns (uint256 root) {
        bytes memory result = challenge3.run(abi.encode(x));
        require(result.length == 32);
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_SqrtExample() external {
        assertEq(run(5), 2);
    }

    /**
     * @notice Selected corner cases.
     */
    function test_SqrtSelectedCases() external {
        assertEq(run(0), 0);
        assertEq(run(1), 1);
        assertEq(run(10), 3);
        assertEq(run(99), 9);
        assertEq(run(100), 10);
        assertEq(run(101), 10);
    }

    /**
     * @notice Casacading effect of square root on powers of two.
     */
    function test_CircleAreaPowersOfTwo() external {
        assertEq(run(type(uint16).max), type(uint8).max);
        assertEq(run(type(uint32).max), type(uint16).max);
        assertEq(run(type(uint64).max), type(uint32).max);
        assertEq(run(type(uint128).max), type(uint64).max);
        assertEq(run(type(uint256).max), type(uint128).max);
    }

    /**
     * @dev Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_Sqrt(uint256 x) external {
        assertEq(run(x), sqrt(x));
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
        assertEq(run(x), sqrt(x));
    }
}
