// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { msb } from "prb-math/Common.sol";

import "../src/Challenge3.sol" as YUL;

/**
 * @title Generate the lookup table for the optimized Square Root algorithm.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Run with `forge script script/Challenge3.s.sol:GenerateDeBruijnTable`.
 */
contract GenerateDeBruijnTable is Script {
    /**
     * @notice Generate table of precomputed `msb()` values for 2-bit indexing.
     */
    function makeTable() private pure returns (uint8[] memory table) {
        table = new uint8[](16);
        for (uint8 i = 0; i < 16; i++) {
            uint256 bit = msb(i);
            uint8 packed = uint8(bit);
            console.log("%s: msb=%s, packed=%s", i, bit, vm.toString(abi.encodePacked(packed)));
            require(bit <= type(uint8).max);
            table[i] = packed;
        }
    }

    /**
     * @notice Pack array of `uint8` values into a byte array.
     */
    function packTable(uint8[] memory values) private pure returns (bytes memory packed) {
        packed = new bytes(values.length);
        for (uint256 i = 0; i < values.length; i++) {
            packed[i] = bytes1(values[i]);
        }
    }

    /**
     * @notice Split byte array into continuous 32-byte words, for indexing with `BYTE` (1A) instruction.
     */
    function splitWords(bytes memory data) private pure returns (bytes32[] memory words) {
        words = new bytes32[]((data.length + 31) >> 5);
        for (uint256 i = 0; i < data.length; i++) {
            words[i >> 5] |= bytes32(data[i]) >> ((i << 3) & 0xFF);
        }
    }

    /**
     * @notice Build lookup table split into 32-byte words.
     */
    function run() external pure returns (bytes32[] memory table) {
        return splitWords(packTable(makeTable()));
    }
}

/**
 * @title Integer Square Root.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Calculate the integer square root $0 \leq n < 2^{256}$.
 * @dev Run with `forge script script/Challenge3.s.sol:Sqrt --sig 'run(uint256)' VALUE`.
 */
contract Sqrt {
    /**
     * @notice Calculate the integer square root of `x`.
     */
    function run(uint256 x) external view returns (uint256 root) {
        uint256 startGas = gasleft();
        root = YUL.sqrt(x);
        uint256 endGas = gasleft();
        console.log("Gas used: %d", startGas - endGas - 2);
    }
}
