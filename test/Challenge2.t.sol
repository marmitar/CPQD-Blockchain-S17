// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Assembler, Runnable, RuntimeContract } from "./Assembler.sol";
import { Test } from "forge-std/Test.sol";

using Runnable for RuntimeContract;

/**
 * @title Unit tests for the Circle Area contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge2Test is Assembler, Test {
    /**
     * @dev Circle area calculation, done in EVM bytecode.
     */
    RuntimeContract private challenge2 = load("src/Challenge2.etk");

    /**
     * @dev Execute `challenge2` to find the approximate area of a circle.
     */
    function run(uint16 radius) private returns (uint256 area) {
        bytes memory result = challenge2.run(abi.encode(radius));
        require(result.length == 32);
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_CircleAreaExamples() external {
        assertEq(run(4), 50);
        assertEq(run(2), 13);
    }

    /**
     * @notice All powers of ten for 16-bit.
     */
    function test_CircleAreaPowersOfTen() external {
        assertEq(run(0), 0);
        assertEq(run(1), 3);
        assertEq(run(10), 314);
        assertEq(run(100), 31_416);
        assertEq(run(1000), 3_141_593);
        assertEq(run(10_000), 314_159_265);
    }

    /**
     * @notice Guarantee that even the largest input radius can't overflow.
     */
    function test_CircleAreaNoOverflow() external {
        assertEq(run(65_535), 13_492_625_933);
    }

    /**
     * @dev Fuzz testing, assuming the area is always between $3 r^2$ and $4 r^2$.
     */
    function testFuzz_CircleArea(uint16 radius) external {
        vm.assume(radius > 0);

        uint256 area = run(radius);
        assertGe(area, 3 * uint256(radius) ** 2);
        assertLt(area, 4 * uint256(radius) ** 2);
    }
}
