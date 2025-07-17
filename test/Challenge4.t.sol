// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Assembler, Runnable, RuntimeContract } from "./Assembler.sol";
import { Test, Vm } from "forge-std/Test.sol";
import { sqrt } from "prb-math/Common.sol";

using Runnable for RuntimeContract;

/**
 * @title Unit tests for the Gas Burner contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge4Test is Assembler, Test {
    /**
     * @dev Gas Burner contract, done in EVM bytecode.
     */
    RuntimeContract private immutable BURNER = load("src/Challenge4.etk");

    /**
     * @notice Verifies that all gas was used, non remain.
     */
    function assertGasUsed(Vm.Gas memory usage, uint256 gasLimit) private noGasMetering {
        assertEq(usage.gasLimit, gasLimit, "gasLimit");
        assertEq(usage.gasTotalUsed, gasLimit, "gasTotalUsed");
        assertEq(usage.gasRefunded, 0, "gasRefunded");
        assertEq(usage.gasRemaining, 0, "gasRemaining");
    }

    /**
     * @dev Minimum amount of gas for the Gas Burner to not revert.
     */
    uint256 private constant LIMIT = 8 + 30 + 22;

    /**
     * @notice Check the very first two passing gas limits.
     */
    function test_BurnerLowerLimit() external {
        assertGasUsed(BURNER.runWithGasLimit(vm, LIMIT), LIMIT);
        assertGasUsed(BURNER.runWithGasLimit(vm, LIMIT + 1), LIMIT + 1);
    }

    /**
     * @notice Check the first non-passing gas limits.
     */
    function test_RevertIf_LessThanLimit() external {
        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertGasUsed(BURNER.runWithGasLimit(vm, LIMIT - 1), 0);
    }

    /**
     * @dev Fuzz testing for the common amount of gas.
     */
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_BurnALotOfGas(uint16 gasLimit) external {
        vm.assume(gasLimit >= LIMIT);

        assertGasUsed(BURNER.runWithGasLimit(vm, gasLimit), gasLimit);
    }

    /**
     * @dev Fuzz testing for large values of gas.
     */
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_BurnAllGas(uint32 gasLimit) external {
        vm.assume(gasLimit >= LIMIT && gasLimit < 1e9);

        assertGasUsed(BURNER.runWithGasLimit(vm, gasLimit), gasLimit);
    }

    /**
     * @notice Fuzz testing all low values of gas.
     */
    function testFuzz_RevertIf_LimitTooLow(uint8 gasLimit) external {
        vm.assume(gasLimit < LIMIT);

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertGasUsed(BURNER.runWithGasLimit(vm, gasLimit), 0);
    }
}
