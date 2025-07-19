// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { StdCheats, Test, TestBase, Vm } from "forge-std/Test.sol";

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
library Runnable {
    /**
     * @notice Return the contract's bytecode (`EXTCODECOPY`).
     */
    function code(RuntimeContract runtime) external view returns (bytes memory bytecode) {
        return RuntimeContract.unwrap(runtime).code;
    }

    /**
     * @notice {RuntimeContract} execution reverted without any specific error.
     */
    error ExecutionReverted();

    /**
     * @notice Executes the {RuntimeContract} and verify successful exection. Input and output unaltered.
     * Gas usage is mesured and returned.
     * @dev Sadly, this must be implemented outside {Assembler}, in new "contract" (or library, in this case).
     */
    /// forge-config: default.optimizer-runs = 2000000
    function staticCall(RuntimeContract runtime, uint256 gasLimit, Vm vm, bytes memory input)
        external
        view
        returns (bytes memory output, Vm.Gas memory usage)
    {
        address deployedCode = RuntimeContract.unwrap(runtime);
        (bool success, bytes memory result) = deployedCode.staticcall{ gas: gasLimit }(input);

        if (success) {
            return (result, vm.lastCallGas());
        } else if (result.length > 0) {
            // custom error
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        } else {
            // generic error
            revert ExecutionReverted();
        }
    }
}

using Decode for bytes;

/**
 * @title Checked conversions from `bytes` data.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
library Decode {
    /**
     * @notice Given `bytes` data cannot be correctly converted to expected type.
     */
    error MismatchedData(uint256 requiredSize, string typeName, uint256 actualSize);

    /**
     * @notice Convert `bytes` to `uint256` safely.
     */
    function asUint256(bytes memory data) external pure returns (uint256 value) {
        require(data.length == 32, MismatchedData(32, "uint256", data.length));
        return abi.decode(data, (uint256));
    }

    /**
     * @notice Empty byte array. Used for the `Unit` type or `void` marker in some programming languages, representing
     * an empty input or output from a function.
     */
    bytes public constant NULL = new bytes(0);

    /**
     * @notice Verifies that `bytes` is empty, as in a `void` return from a function call.
     */
    function asVoid(bytes memory data) external pure {
        require(data.length == 0, MismatchedData(0, "()", data.length));
    }
}

/**
 * @title Test utility for assembling EVM bytecode at runtime.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Assembler is TestBase, StdCheats {
    /**
     * @notice Assembles bytecode from file located at `pathToMnemonic` and create a new runtime contract with it.
     */
    function assemble(string memory pathToMnemonic) public returns (RuntimeContract runtime) {
        return create(eas(pathToMnemonic), pathToMnemonic);
    }

    /**
     * @notice Assembles bytecode from file located at `pathToMnemonic` using [eas](https://github.com/quilt/etk).
     */
    function eas(string memory pathToMnemonic) private returns (bytes memory bytecode) {
        string[] memory cmd = new string[](2);
        cmd[0] = "eas";
        cmd[1] = pathToMnemonic;

        return vm.ffi(cmd);
    }

    /**
     * @notice Load bytecode from a file located at `pathToBytecodeHex` and create a new runtime contract with it.
     */
    function load(string memory pathToBytecodeHex) internal returns (RuntimeContract runtime) {
        string memory bytecodeHex = string.concat("0x", vm.trim(vm.readFile(pathToBytecodeHex)));
        return create(vm.parseBytes(bytecodeHex), pathToBytecodeHex);
    }

    /**
     * @notice Runtime code is empty.
     */
    error EmptyBytecode();

    /**
     * @notice Label given for the {RuntimeContract} is empty.
     */
    error EmptyLabel();

    /**
     * @notice Create a new contract with `bytecode`. It appends `GENERIC_CONSTRUCTOR_BYTECODE` to deploy the contract.
     * @param debugLabel Name of the for debugging purposes.
     * @dev Based on <https://github.com/Lohann/trabalho-seguranca-evm/blob/master/src/LowLevelUtils.sol>.
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

    /**
     * @notice Executes the {RuntimeContract} and verify successful exection. Input and output unaltered.
     * @dev Gas usage is mesured and stored in {lastCallGas}.
     */
    /// forge-config: default.optimizer-runs = 2000000
    function run(uint256 gasLimit, RuntimeContract runtime, bytes memory input)
        internal
        noGasMetering
        returns (bytes memory output)
    {
        vm.resumeGasMetering();
        (output, lastCallGas) = runtime.staticCall(gasLimit, vm, input);
        vm.pauseGasMetering();
    }

    /**
     * @notice Gas usage in the last {RuntimeContract} call.
     */
    Vm.Gas internal lastCallGas;

    /**
     * @notice Verifies that an specific amount of gas was used.
     */
    function assertGasUsed(uint256 gasLimit, uint256 gasUsed) internal noGasMetering {
        vm.assertEq(lastCallGas.gasLimit, gasLimit, "gasLimit");
        vm.assertEq(lastCallGas.gasTotalUsed, gasUsed, "gasTotalUsed");
        vm.assertEq(lastCallGas.gasMemoryUsed, 0, "gasMemoryUsed (DEPRECATED)");
        vm.assertEq(lastCallGas.gasRefunded, 0, "gasRefunded");
        vm.assertEq(lastCallGas.gasRemaining, gasLimit - gasUsed, "gasRemaining");
    }

    /**
     * @notice Verifies that all gas was used, none remain.
     */
    function assertGasUsed(uint256 gasLimit) internal noGasMetering {
        assertGasUsed(gasLimit, gasLimit);
    }
}

/**
 * @title Unit tests for {{Assembler}}.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract AssemblerTest is Assembler, Test {
    /**
     * @notice Bytecode for the identity function, $f(x) = x$.
     */
    string private constant IDENTITY = "test/Identity.evm";

    /**
     * @notice Verify that it assembles into the expected binary.
     */
    function test_AssemblesBytecode() external {
        assertEq(assemble(IDENTITY).code(), hex"5f_35_5f_52_60_20_5f_f3", "assembled IDENTITY");
    }

    /**
     * @notice Verify that it returns the input value unchanged.
     */
    function testFuzz_BytecodeRuns(uint256 value) external {
        RuntimeContract runtime = assemble(IDENTITY);
        assertEq(run(18, runtime, abi.encode(value)).asUint256(), value, "IDENTITY output");
        assertEq(vm.getLabel(RuntimeContract.unwrap(runtime)), IDENTITY, "IDENTITY label");
    }

    /**
     * @notice Forbid empty contracts after `GENERIC_CONSTRUCTOR_BYTECODE`.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function test_RevertIf_ContractIsEmpty() external {
        assertEq(Decode.NULL.length, 0, "NULL reference");

        vm.expectRevert(Assembler.EmptyBytecode.selector);
        RuntimeContract failed = create(Decode.NULL, "VOID");

        assertEq(RuntimeContract.unwrap(failed), address(0), "reverted create");
    }

    /**
     * @notice Forbid empty debug labels, if used.
     */
    /// forge-config: default.allow_internal_expect_revert = true
    function test_RevertIf_LabelIsEmpty() external {
        bytes memory bytecode = assemble(IDENTITY).code();

        vm.expectRevert(Assembler.EmptyLabel.selector);
        RuntimeContract failed = create(bytecode, "           ");

        assertEq(RuntimeContract.unwrap(failed), address(0), "reverted create");
    }

    /**
     * @notice Bytecode with the `REVERT` instruction.
     *
     * PUSH2 0x3a28
     * PUSH0
     * MSTORE
     * PUSH1 0x02
     * PUSH1 0x1e
     * REVERT
     */
    bytes10 private constant REVERT_BYTECODE = 0x613a285f526002601efd;

    /**
     * @notice Check that a revert in the bytecode causes an {ExecutionReverted} error.
     */
    function test_RevertIf_BytecodeReverts() external {
        RuntimeContract runtime = create(abi.encodePacked(REVERT_BYTECODE), "REVERT_BYTECODE");

        vm.expectRevert(bytes(":("));
        assertEq(run(17, runtime, Decode.NULL), Decode.NULL, "reverted run");
    }

    /**
     * @notice Hexadecimal value of the `STOP` instruction.
     */
    bytes1 private constant STOP_BYTECODE = 0x00;

    /**
     * @notice Check that invalid output causes an {MismatchedData} error.
     */
    function test_RevertIf_MismatchedDataOnStop() external {
        RuntimeContract runtime = create(abi.encodePacked(STOP_BYTECODE), "STOP_BYTECODE");

        bytes memory output = run(0, runtime, Decode.NULL);
        vm.expectRevert(abi.encodeWithSelector(Decode.MismatchedData.selector, 32, "uint256", 0));
        assertEq(output.asUint256(), 0, "not enough bytes for uint256");
    }

    /**
     * @notice Check that invalid output causes an {MismatchedOutput} error.
     */
    function test_StopDoesntSpendGas() external {
        RuntimeContract runtime = create(abi.encodePacked(STOP_BYTECODE), "STOP_BYTECODE");
        run(1, runtime, Decode.NULL).asVoid();

        assertGasUsed(1, 0);
    }

    /**
     * @notice Simple bytecode that uses 33 gas.
     *
     *  PUSH0
     *  PUSH0
     *  KECCAK256
     */
    bytes private constant USES_33_GAS = hex"5f_5f_20";

    /**
     * @notice Check that using more gas than limit causes a revert.
     */
    function test_RevertIf_SpentTooMuchGas() external {
        RuntimeContract runtime = create(abi.encodePacked(USES_33_GAS), "USES_33_GAS");

        vm.expectRevert(Runnable.ExecutionReverted.selector);
        run(20, runtime, Decode.NULL).asVoid();

        assertGasUsed(0);
    }

    /**
     * @notice Check that invalid output causes an {MismatchedData} error.
     */
    function test_RevertIf_MismatchedDataOnIdentityGasMeasurements() external {
        RuntimeContract runtime = assemble(IDENTITY);

        bytes memory output = run(100, runtime, abi.encode(10));
        vm.expectRevert(abi.encodeWithSelector(Decode.MismatchedData.selector, 0, "()", 32));
        output.asVoid();

        assertGasUsed(100, 18);
    }
}
