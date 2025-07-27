// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import { PI, UD60x18, convert, ud } from "prb-math/UD60x18.sol";

import "../src/Challenge2.sol" as YUL;
import { Assembler, Decode, RuntimeContract } from "./Assembler.sol";

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
        assertEq(CIRCLE_AREA.code(), distributed.code(), "distributed code");
    }

    /**
     * @notice Gas used by {CIRCLE_AREA}.
     */
    uint8 private constant GAS_LIMIT = 48;

    /**
     * @notice Calculate the area of a circle of the give `radius`, rounded to the nearest integer.
     */
    function circleArea(uint256 radius) private noGasMetering returns (uint256 area) {
        area = run(GAS_LIMIT, CIRCLE_AREA, abi.encode(radius)).asUint256();
        assertGasUsed(GAS_LIMIT, GAS_LIMIT);
        assertEq(YUL.circleArea(radius), area, "Yul assembly");
    }

    /**
     * @notice Precise implementation of {circleArea} using [`prb-math`](https://github.com/PaulRBerg/prb-math).
     */
    function expectedCircleArea(uint256 radius) private pure returns (uint256 area) {
        UD60x18 uArea = convert(radius).powu(2) * PI;
        return convert(uArea + ud(0.5e18));
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_CircleAreaExamples() external {
        assertEq(circleArea(4), 50, "r = 4");
        assertEq(circleArea(2), 13, "r = 2");
    }

    /**
     * @notice All powers of ten for 16-bit.
     */
    function test_CircleAreaPowersOfTen() external {
        assertEq(circleArea(0), 0, "r = 0");
        assertEq(circleArea(1), 3, "r = 10**0");
        assertEq(circleArea(10), 314, "r = 10**1");
        assertEq(circleArea(100), 31_416, "r = 10**2");
        assertEq(circleArea(1000), 3_141_593, "r = 10**3");
        assertEq(circleArea(10_000), 314_159_265, "r = 10**4");
    }

    /**
     * @notice Radius must be between 0 and this value.
     */
    uint16 private constant MAX_RADIUS = 65_535;

    /**
     * @notice Guarantee that even the largest input radius can't overflow, but one more than it does.
     */
    function test_CircleAreaNoOverflow() external {
        assertEq(circleArea(MAX_RADIUS), 13_492_625_933, "r = MAX_RADIUS");
        assertEq(circleArea(uint256(MAX_RADIUS) + 1), 0, "r = MAX_RADIUS+1 overflows");
    }

    /**
     * @notice Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_CircleArea(uint16 radius) external {
        assertEq(circleArea(radius), expectedCircleArea(radius), "0 <= r <= MAX_RADIUS");
    }

    /**
     * @notice Ensure radius over teh maximum gives garbage responses.
     */
    function testFuzz_CircleAreaOverflowsAfterMaxRadius(uint16 overRadius) external {
        uint256 radius = uint256(MAX_RADIUS) + 1 + uint256(overRadius);
        string memory message = string.concat("r = ", vm.toString(radius), " overflows");
        assertNotEq(circleArea(radius), expectedCircleArea(radius), message);
    }
}
