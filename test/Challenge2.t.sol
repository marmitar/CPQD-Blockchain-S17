// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import { PI, UD60x18, convert, ud } from "prb-math/UD60x18.sol";

import { Assembler, Decode, Runnable, RuntimeContract } from "./Assembler.sol";

using Runnable for RuntimeContract;
using Decode for bytes;

/**
 * @title Unit tests for the Circle Area contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge2Test is Assembler, Test {
    /**
     * @notice Circle area calculation, done in EVM bytecode.
     */
    RuntimeContract private immutable CIRCLE_AREA = assemble("src/Challenge2.evm");

    /**
     * @notice Verify distributed assembly.
     */
    function test_CircleAreaAssembly() external {
        RuntimeContract distributed = load("dist/AreaCirculo.hex");
        assertEq(CIRCLE_AREA.code(), distributed.code());
    }

    /**
     * @notice Calculate the area of a circle of the give `radius`, rounded to the nearest integer.
     */
    function circleArea(uint256 radius) private returns (uint256 area) {
        return run(CIRCLE_AREA, abi.encode(radius)).asUint256();
    }

    /**
     * @notice Precise implementation of {circleArea} using [`prb-math`](https://github.com/PaulRBerg/prb-math).
     */
    function expectedCircleArea(uint256 radius) private pure returns (uint256 area) {
        UD60x18 uArea = convert(radius).powu(2).mul(PI);
        return convert(uArea.add(ud(0.5e18)));
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_CircleAreaExamples() external {
        assertEq(circleArea(4), 50);
        assertEq(circleArea(2), 13);
    }

    /**
     * @notice All powers of ten for 16-bit.
     */
    function test_CircleAreaPowersOfTen() external {
        assertEq(circleArea(0), 0);
        assertEq(circleArea(1), 3);
        assertEq(circleArea(10), 314);
        assertEq(circleArea(100), 31_416);
        assertEq(circleArea(1000), 3_141_593);
        assertEq(circleArea(10_000), 314_159_265);
    }

    /**
     * @notice Guarantee that even the largest input radius can't overflow.
     */
    function test_CircleAreaNoOverflow() external {
        assertEq(circleArea(65_535), 13_492_625_933);
    }

    /**
     * @notice Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_CircleArea(uint16 radius) external {
        assertEq(circleArea(radius), expectedCircleArea(radius));
    }
}
