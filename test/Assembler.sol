// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test, TestBase, Vm } from "forge-std/Test.sol";

/**
 * @title Address of a dynamically assembled contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Safe wrapper over an `address`.
 * @dev Based on <https://github.com/Analog-Labs/evm-interpreter/blob/main/src/utils/InterpreterUtils.sol>.
 */
type RuntimeContract is address;

/**
 * @dev Based on <https://github.com/Analog-Labs/evm-interpreter/blob/main/src/utils/Executor.sol>.
 */
using Runnable for RuntimeContract;

/**
 * @title Checked executions for {RuntimeContract}.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Based on <https://github.com/Analog-Labs/evm-interpreter/blob/main/src/utils/InterpreterUtils.sol>.
 */
/// forge-config: default.optimizer-runs = 200000
library Runnable {
    /**
     * @notice Return the contract's bytecode (`EXTCODECOPY`).
     */
    function code(RuntimeContract runtime) public view returns (bytes memory bytecode) {
        return RuntimeContract.unwrap(runtime).code;
    }

    /**
     * @dev Pre-defined gas limit for bytecode contracts.
     */
    uint256 private constant DEFAULT_GAS_LIMIT = 100_000;

    /**
     * @notice {RuntimeContract} execution reverted.
     */
    error ExecutionReverted();

    /**
     * @notice Executes the {RuntimeContract} and verify successful exection. Input and output unaltered.
     */
    function run(RuntimeContract runtime, bytes memory input) public returns (bytes memory output) {
        address deployedCode = RuntimeContract.unwrap(runtime);
        (bool success, bytes memory result) = deployedCode.call{ gas: DEFAULT_GAS_LIMIT }(input);
        require(success, ExecutionReverted());
        return result;
    }

    /**
     * @notice {RuntimeContract} returned a different number of outputs.
     */
    error MismatchedOutput();

    /**
     * @notice Executes the {RuntimeContract} assuming a single 32-bit input and output.
     */
    function run(RuntimeContract runtime, uint256 input) external returns (uint256 output) {
        bytes memory result = run(runtime, abi.encode(input));
        require(result.length == 32, MismatchedOutput());
        return abi.decode(result, (uint256));
    }

    /**
     * @dev Empty byte array.
     */
    bytes constant NULL = new bytes(0);

    /**
     * @notice Executes the {RuntimeContract} with the given `gasLimit` and measure `usage`.
     */
    function runWithGasLimit(RuntimeContract runtime, Vm vm, uint256 gasLimit) external returns (Vm.Gas memory usage) {
        address deployedCode = RuntimeContract.unwrap(runtime);

        (bool success, bytes memory result) = deployedCode.call{ gas: gasLimit }(NULL);
        usage = vm.lastCallGas();

        require(success, ExecutionReverted());
        require(result.length == NULL.length, MismatchedOutput());
    }
}

/**
 * @title Test utility for assembling EVM bytecode at runtime.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
abstract contract Assembler is TestBase {
    /**
     * @dev Assembles bytecode from file located at `pathToMnemonic` and create a new runtime contract with it.
     */
    function assemble(string memory pathToMnemonic) internal returns (RuntimeContract runtime) {
        return create(eas(pathToMnemonic), pathToMnemonic);
    }

    /**
     * @dev Assembles bytecode from file located at `pathToMnemonic` using [eas](https://github.com/quilt/etk).
     */
    function eas(string memory pathToMnemonic) private returns (bytes memory bytecode) {
        string[] memory cmd = new string[](2);
        cmd[0] = "eas";
        cmd[1] = pathToMnemonic;

        return vm.ffi(cmd);
    }

    /**
     * @dev Load bytecode from a file located at `pathToBytecodeHex` and create a new runtime contract with it.
     */
    function load(string memory pathToBytecodeHex) internal returns (RuntimeContract runtime) {
        string memory bytecodeHex = string.concat("0x", vm.trim(vm.readFile(pathToBytecodeHex)));
        return create(vm.parseBytes(bytecodeHex), pathToBytecodeHex);
    }

    /**
     * @dev Runtime code is empty.
     */
    error EmptyBytecode();

    /**
     * @dev Label given for the {RuntimeContract} is empty.
     */
    error EmptyLabel();

    /**
     * @notice Create a new contract with `bytecode`. It appends `GENERIC_CONSTRUCTOR_BYTECODE` to deploy the contract.
     * @param debugLabel Name of the for debugging purposes.
     * @dev From <https://github.com/Lohann/trabalho-seguranca-evm/blob/master/src/LowLevelUtils.sol>.
     */
    function create(bytes memory bytecode, string memory debugLabel) internal returns (RuntimeContract runtime) {
        require(bytecode.length > 0, EmptyBytecode());
        string memory label = vm.trim(debugLabel);
        require(bytes(label).length > 0, EmptyLabel());

        uint256 genericConstructorBytecodeLen = abi.encodePacked(GENERIC_CONSTRUCTOR_BYTECODE).length;
        // This code is memory safe because it alters then restores the memory
        assembly ("memory-safe") {
            // load bytecode.length
            let len := mload(bytecode)
            // Prefix `bytecode` with `GENERIC_CONSTRUCTOR_BYTECODE`
            mstore(bytecode, GENERIC_CONSTRUCTOR_BYTECODE)
            {
                // constructor memory offset
                let offset := add(bytecode, sub(32, genericConstructorBytecodeLen))
                // constructor length in bytes
                let size := add(len, genericConstructorBytecodeLen)
                runtime := create(0, offset, size)
            }
            // Restore bytecode.length
            mstore(bytecode, len)
        }

        vm.label(RuntimeContract.unwrap(runtime), label);
    }

    /**
     * Generic constructor bytecode, used to deploy contracts provided the runtime.
     *
     * 0x600b38035f81600b5f39f3
     * 0x00   600b   PUSH1 0x0b
     * 0x02   38     CODESIZE
     * 0x03   03     SUB
     * 0x04   5f     PUSH0
     * 0x05   81     DUP2
     * 0x06   600b   PUSH1 0x0b
     * 0x08   5f     PUSH0
     * 0x09   39     CODECOPY
     * 0x0a   f3     RETURN
     *
     * @dev From <https://github.com/Lohann/trabalho-seguranca-evm/blob/master/src/LowLevelUtils.sol>.
     */
    uint88 private constant GENERIC_CONSTRUCTOR_BYTECODE = 0x600b38035f81600b5f39f3;
}

/**
 * @title Unit tests for {{Assembler}}.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract AssemblerTest is Assembler, Test {
    /**
     * @dev Bytecode for the identity function, $f(x) = x$.
     */
    string private constant IDENTITY = "test/Identity.evm";

    /**
     * @dev Verify that it assembles into the expected binary.
     */
    function test_AssemblesBytecode() external {
        assertEq(assemble(IDENTITY).code(), hex"5f_35_5f_52_60_20_5f_f3");
    }

    /**
     * @dev Verify that it returns the input value unchanged.
     */
    function testFuzz_BytecodeRuns(uint256 value) external {
        RuntimeContract runtime = assemble(IDENTITY);
        assertEq(runtime.run(value), value);
        assertEq(vm.getLabel(RuntimeContract.unwrap(runtime)), IDENTITY);
    }

    /**
     * @dev Forbid empty contracts after `GENERIC_CONSTRUCTOR_BYTECODE`.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function test_RevertIf_ContractIsEmpty() external {
        assertEq(Runnable.NULL.length, 0);

        vm.expectRevert(Assembler.EmptyBytecode.selector);
        RuntimeContract failed = create(Runnable.NULL, "NULL");

        assertEq(RuntimeContract.unwrap(failed), address(0));
    }

    /**
     * @dev Forbid empty debug labels, if used.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function test_RevertIf_LabelIsEmpty() external {
        bytes memory bytecode = assemble(IDENTITY).code();

        vm.expectRevert(Assembler.EmptyLabel.selector);
        RuntimeContract failed = create(bytecode, "           ");

        assertEq(RuntimeContract.unwrap(failed), address(0));
    }

    /**
     * @dev Hexadecimal value of the `REVERT` instruction.
     */
    bytes1 private constant REVERT_BYTECODE = 0xfd;

    /**
     * @dev Check that a revert in the bytecode causes an {ExecutionReverted} error.
     */
    function test_RevertIf_BytecodeReverts() external {
        RuntimeContract runtime = create(abi.encodePacked(REVERT_BYTECODE), "REVERT_BYTECODE");

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertEq(runtime.run(Runnable.NULL), Runnable.NULL);
    }

    /**
     * @dev Hexadecimal value of the `STOP` instruction.
     */
    bytes1 private constant STOP_BYTECODE = 0x00;

    /**
     * @dev Check that invalid output causes an {MismatchedOutput} error.
     */
    function test_RevertIf_MismatchedOutputOnStop() external {
        RuntimeContract runtime = create(abi.encodePacked(STOP_BYTECODE), "STOP_BYTECODE");

        vm.expectRevert(Runnable.MismatchedOutput.selector);
        assertEq(runtime.run(0), 0);
    }

    /**
     * @dev Check that invalid output causes an {MismatchedOutput} error.
     */
    function test_StopDoesntSpendGas() external {
        RuntimeContract runtime = create(abi.encodePacked(STOP_BYTECODE), "STOP_BYTECODE");
        Vm.Gas memory usage = runtime.runWithGasLimit(vm, 1);

        assertEq(usage.gasLimit, 1);
        assertEq(usage.gasTotalUsed, 0);
        assertEq(usage.gasRefunded, 0);
        assertEq(usage.gasRemaining, 1);
    }

    /**
     * @dev Simple bytecode that uses 33 gas.
     *
     *  PUSH0
     *  PUSH0
     *  KECCAK256
     */
    bytes private constant USES_33_GAS = hex"5f_5f_20";

    /**
     * @dev Check that invalid output causes an {MismatchedOutput} error.
     */
    function test_RevertIf_SpentTooMuchGas() external {
        RuntimeContract runtime = create(abi.encodePacked(USES_33_GAS), "USES_33_GAS");

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        Vm.Gas memory usage = runtime.runWithGasLimit(vm, 20);

        assertEq(usage.gasLimit, 0);
        assertEq(usage.gasTotalUsed, 0);
        assertEq(usage.gasRefunded, 0);
        assertEq(usage.gasRemaining, 0);
    }

    /**
     * @dev Check that invalid output causes an {MismatchedOutput} error.
     */
    function test_RevertIf_MismatchedOutputOnIdentityGasMeasurements() external {
        RuntimeContract runtime = assemble(IDENTITY);

        vm.expectRevert(Runnable.MismatchedOutput.selector);
        Vm.Gas memory usage = runtime.runWithGasLimit(vm, 100);

        assertEq(usage.gasLimit, 0);
        assertEq(usage.gasTotalUsed, 0);
        assertEq(usage.gasRefunded, 0);
        assertEq(usage.gasRemaining, 0);
    }
}
