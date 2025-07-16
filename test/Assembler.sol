// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { TestBase } from "forge-std/Base.sol";
import { Test } from "forge-std/Test.sol";

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
    function run(RuntimeContract code, bytes memory input) public returns (bytes memory output) {
        address deployedCode = RuntimeContract.unwrap(code);
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
    function run(RuntimeContract code, uint256 input) external returns (uint256 output) {
        bytes memory result = run(code, abi.encode(input));
        require(result.length == 32, MismatchedOutput());
        return abi.decode(result, (uint256));
    }
}

/**
 * @title Test utility for assembling EVM bytecode at runtime.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
abstract contract Assembler is TestBase {
    /**
     * @dev Assembles bytecode from file located at `pathToMnemonic`.
     */
    function assemble(string memory pathToMnemonic) internal returns (bytes memory bytecode) {
        string[] memory cmd = new string[](2);
        cmd[0] = "eas";
        cmd[1] = pathToMnemonic;

        return vm.ffi(cmd);
    }

    /**
     * @dev Assembles bytecode from file located at `pathToMnemonic` and create a new runtime contract with it.
     */
    function load(string memory pathToMnemonic) internal returns (RuntimeContract runtime) {
        return create(assemble(pathToMnemonic));
    }

    /**
     * Generic constructor bytecode, used to deploy contracts provided the runtime.
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
    uint256 private constant GENERIC_CONSTRUCTOR_BYTECODE = 0x600b38035f81600b5f39f3;

    /**
     * The size in bytes of `GENERIC_CONSTRUCTOR_BYTECODE`.
     *
     * @dev From <https://github.com/Lohann/trabalho-seguranca-evm/blob/master/src/LowLevelUtils.sol>.
     */
    uint256 internal constant GENERIC_CONSTRUCTOR_BYTECODE_LEN = 11;

    /**
     * @dev Runtime code is empty.
     */
    error EmptyBytecode();

    /**
     * @notice Create a new contract with `bytecode`. It appends `GENERIC_CONSTRUCTOR_BYTECODE` to deploy the contract.
     *
     * @dev From <https://github.com/Lohann/trabalho-seguranca-evm/blob/master/src/LowLevelUtils.sol>.
     */
    function create(bytes memory bytecode) internal returns (RuntimeContract runtime) {
        require(bytecode.length > 0, EmptyBytecode());

        // This code is memory safe because it alters then restores the memory
        assembly ("memory-safe") {
            // load bytecode.length
            let len := mload(bytecode)
            // Prefix `bytecode` with `GENERIC_CONSTRUCTOR_BYTECODE`
            mstore(bytecode, GENERIC_CONSTRUCTOR_BYTECODE)
            {
                // constructor memory offset
                let offset := add(bytecode, sub(32, GENERIC_CONSTRUCTOR_BYTECODE_LEN))
                // constructor length in bytes
                let size := add(len, GENERIC_CONSTRUCTOR_BYTECODE_LEN)
                runtime := create(0, offset, size)
            }
            // Restore bytecode.length
            mstore(bytecode, len)
        }
    }
}

/**
 * @title Unit tests for {{Assembler}}.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract AssemblerTest is Assembler, Test {
    /**
     * @dev Bytecode for the identity function, $f(x) = x$.
     */
    string private constant IDENTITY = "test/Identity.etk";

    /**
     * @dev Verify that it assembles into the expected binary.
     */
    function test_AssemblesBytecode() external {
        assertEq(assemble(IDENTITY), hex"5f_35_5f_52_60_20_5f_f3");
    }

    /**
     * @dev Verify that it returns the input value unchanged.
     */
    function testFuzz_BytecodeRuns(uint256 value) external {
        RuntimeContract runtime = load(IDENTITY);
        assertEq(runtime.run(value), value);
    }

    /**
     * @dev Empty byte array.
     */
    bytes constant NODATA = new bytes(0);

    /**
     * @dev Forbid empty contracts after `GENERIC_CONSTRUCTOR_BYTECODE`.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function test_RevertIf_ContractIsEmpty() external {
        assertEq(NODATA.length, 0);

        vm.expectRevert(Assembler.EmptyBytecode.selector);
        RuntimeContract failed = create(NODATA);

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
        RuntimeContract runtime = create(abi.encodePacked(REVERT_BYTECODE));

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        assertEq(runtime.run(NODATA), NODATA);
    }
}
