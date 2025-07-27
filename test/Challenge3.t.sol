// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";

import "../src/Challenge3.sol" as YUL;
import { Assembler, Decode, RuntimeContract } from "./Assembler.sol";

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
    uint16 private constant GAS_LIMIT = 367;

    /**
     * @notice Calculates the square root of `x`, returning its integer part.
     */
    function iSqrt(uint256 x) private noGasMetering returns (uint256 root) {
        root = run(GAS_LIMIT, SQRT, abi.encode(x)).asUint256();
        assertGasUsed(GAS_LIMIT);
        assertEq(YUL.sqrt(x), root, "Yul assembly");
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
        assertEq(iSqrt(2 ** 2 - 1), 2 ** 1 - 1, "sqrt(2^2-1)");
        assertEq(iSqrt(2 ** 2), 2 ** 1, "sqrt(2^2)");
        assertEq(iSqrt(2 ** 4 - 1), 2 ** 2 - 1, "sqrt(2^4-1)");
        assertEq(iSqrt(2 ** 4), 2 ** 2, "sqrt(2^4)");
        assertEq(iSqrt(2 ** 8 - 1), 2 ** 4 - 1, "sqrt(2^8-1)");
        assertEq(iSqrt(2 ** 8), 2 ** 4, "sqrt(2^8)");
        assertEq(iSqrt(2 ** 16 - 1), 2 ** 8 - 1, "sqrt(2^16-1)");
        assertEq(iSqrt(2 ** 16), 2 ** 8, "sqrt(2^16)");
        assertEq(iSqrt(2 ** 32 - 1), 2 ** 16 - 1, "sqrt(2^32-1)");
        assertEq(iSqrt(2 ** 32), 2 ** 16, "sqrt(2^32)");
        assertEq(iSqrt(2 ** 64 - 1), 2 ** 32 - 1, "sqrt(2^64-1)");
        assertEq(iSqrt(2 ** 64), 2 ** 32, "sqrt(2^64)");
        assertEq(iSqrt(2 ** 128 - 1), 2 ** 64 - 1, "sqrt(2^128-1)");
        assertEq(iSqrt(2 ** 128), 2 ** 64, "sqrt(2^128)");
        assertEq(iSqrt(2 ** 256 - 1), 2 ** 128 - 1, "sqrt(2^256-1)");
    }

    /**
     * @notice Square root of `type(uint256).max`.
     */
    uint256 constant MAX_SQRT_UINT256 = type(uint128).max;

    /**
     * @notice Take the integer square root and verify the required properties.
     * @param variant Debug label.
     */
    function checkedSqrt(uint256 x, string memory variant) private {
        uint256 r = iSqrt(x);
        assertLe(r, MAX_SQRT_UINT256, "sqrt(x)^2 overflow");

        assertGe(x, r * r, string.concat(variant, " x >= sqrt(x)^2"));
        if (r + 1 <= MAX_SQRT_UINT256) {
            assertLe(x, (r + 1) * (r + 1), string.concat(variant, " x < (sqrt(x) + 1)^2"));
        }
    }

    /**
     * @notice Fuzz testing on `uint16`. Mathematical properties checked.
     */
    function testFuzz_Sqrt16(uint16 x) external {
        checkedSqrt(x, "uint16");
    }

    /**
     * @notice Fuzz testing on `uint32`. Mathematical properties checked.
     */
    function testFuzz_Sqrt32(uint32 x) external {
        checkedSqrt(x, "uint32");
    }

    /**
     * @notice Fuzz testing on `uint64`. Mathematical properties checked.
     */
    function testFuzz_Sqrt64(uint64 x) external {
        checkedSqrt(x, "uint64");
    }

    /**
     * @notice Fuzz testing on `uint128`. Mathematical properties checked.
     */
    function testFuzz_Sqrt128(uint128 x) external {
        checkedSqrt(x, "uint128");
    }

    /**
     * @notice Fuzz testing on `uint256`. Mathematical properties checked.
     */
    function testFuzz_Sqrt256(uint256 x) public {
        checkedSqrt(x, "uint256");
    }

    /**
     * @notice Fuzz testing, focused on very large numbers.
     */
    function testFuzz_SqrtBig(uint256 seed) external {
        // shuffle input to favor large values
        uint256 bigX = uint256(keccak256(abi.encode(seed)));
        checkedSqrt(bigX, "big uint256");
    }
}
