// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test, Vm } from "forge-std/Test.sol";

import { Assembler, Decode, Runnable, RuntimeContract } from "./Assembler.sol";

using Runnable for RuntimeContract;
using Decode for bytes;

/**
 * @title Unit tests for the Gas Burner contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge4Test is Assembler, Test {
    /**
     * @notice Gas Burner contract, done in EVM bytecode.
     */
    RuntimeContract private immutable BURNER = assemble("src/Challenge4.evm");

    /**
     * @notice Verify distributed assembly.
     */
    function test_BurnerAssembly() external {
        RuntimeContract distributed = load("dist/Desafio.hex");
        assertEq(BURNER.code(), distributed.code());
    }

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
     * @notice Minimum amount of gas for the Gas Burner to not revert.
     */
    uint256 private constant LIMIT = 8 + 30 + 22;

    /**
     * @notice Precise implementation using `prb-math`.
     */
    function burn(uint256 gas) private returns (Vm.Gas memory usage) {
        (bytes memory output, Vm.Gas memory gasUsage) = run(gas, BURNER, Decode.NULL);
        output.asVoid();
        return gasUsage;
    }

    /**
     * @notice Check the very first two passing gas limits.
     */
    function test_BurnerLowerLimit() external {
        assertGasUsed(burn(LIMIT), LIMIT);
        assertGasUsed(burn(LIMIT + 1), LIMIT + 1);
    }

    /**
     * @notice Check the first non-passing gas limits.
     */
    function test_RevertIf_LessThanLimit() external {
        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertGasUsed(burn(LIMIT - 1), 0);
    }

    /**
     * notice Fuzz testing for the common amount of gas.
     */
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_BurnALotOfGas(uint16 gasLimit) external {
        vm.assume(gasLimit >= LIMIT);

        assertGasUsed(burn(gasLimit), gasLimit);
    }

    /**
     * @notice Fuzz testing for large values of gas.
     */
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_BurnAllGas(uint32 gasLimit) external {
        // more than 1e9 and the test goes out of gas
        vm.assume(gasLimit >= LIMIT && gasLimit < 1e9);

        assertGasUsed(burn(gasLimit), gasLimit);
    }

    /**
     * @notice Fuzz testing all low values of gas.
     */
    function testFuzz_RevertIf_LimitTooLow(uint8 gasLimit) external {
        vm.assume(gasLimit < LIMIT);

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertGasUsed(burn(gasLimit), 0);
    }
}
