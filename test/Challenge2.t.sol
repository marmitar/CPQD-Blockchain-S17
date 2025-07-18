// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Assembler, Runnable, RuntimeContract } from "./Assembler.sol";
import { Test } from "forge-std/Test.sol";
import { PI, UD60x18, convert, ud } from "prb-math/UD60x18.sol";

using Runnable for RuntimeContract;

/**
 * @title Unit tests for the Circle Area contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge2Test is Assembler, Test {
    /**
     * @dev Circle area calculation, done in EVM bytecode.
     */
    RuntimeContract private immutable CIRCLE_AREA = load("src/Challenge2.etk");

    /**
     * @notice Verify distributed assembly.
     */
    function test_CircleAreaAssembly() external {
        string memory bytecode = string.concat("0x", vm.trim(vm.readFile("dist/AreaCirculo.hex")));
        assertEq(assemble("src/Challenge2.etk"), vm.parseBytes(bytecode));
    }

    /**
     * @notice Examples from the challenge definition.
     */
    function test_CircleAreaExamples() external {
        assertEq(CIRCLE_AREA.run(4), 50);
        assertEq(CIRCLE_AREA.run(2), 13);
    }

    /**
     * @notice All powers of ten for 16-bit.
     */
    function test_CircleAreaPowersOfTen() external {
        assertEq(CIRCLE_AREA.run(0), 0);
        assertEq(CIRCLE_AREA.run(1), 3);
        assertEq(CIRCLE_AREA.run(10), 314);
        assertEq(CIRCLE_AREA.run(100), 31_416);
        assertEq(CIRCLE_AREA.run(1000), 3_141_593);
        assertEq(CIRCLE_AREA.run(10_000), 314_159_265);
    }

    /**
     * @notice Guarantee that even the largest input radius can't overflow.
     */
    function test_CircleAreaNoOverflow() external {
        assertEq(CIRCLE_AREA.run(65_535), 13_492_625_933);
    }

    /**
     * @notice Precise implementation using `prb-math`.
     */
    function circleArea(uint256 radius) private noGasMetering returns (uint256 area) {
        UD60x18 uArea = convert(radius).powu(2).mul(PI);
        return convert(uArea.add(ud(0.5e18)));
    }

    /**
     * @dev Fuzz testing, comparing to a precise implementation.
     */
    function testFuzz_CircleArea(uint16 radius) external {
        assertEq(CIRCLE_AREA.run(radius), circleArea(radius));
    }
}
