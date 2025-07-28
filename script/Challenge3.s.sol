// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { HALF_UNIT, UD60x18, ZERO, convert } from "prb-math/UD60x18.sol";

import "../src/Challenge3.sol" as YUL;

/**
 * @title Generate the lookup table for the optimized Square Root algorithm.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Run with `forge script script/Challenge3.s.sol:GenerateDeBruijnTable`.
 */
contract GenerateDeBruijnTable is Script {
    /**
     * @notice Calculate the average of all square roots in `[start, stop)`.
     */
    function sqrtAverage(uint256 start, uint256 stop) private pure returns (UD60x18 average) {
        UD60x18 sum = ZERO;
        uint256 count = 0;
        for (uint256 x = start; x < stop; x++) {
            sum = sum + convert(x).sqrt();
            count += 1;
        }
        return sum / convert(count);
    }

    /**
     * @notice Pack the value of a square root of a `uint8` in a byte.
     */
    function packRounded(UD60x18 value) private pure returns (uint8 packed) {
        uint256 rounded = convert(value + HALF_UNIT);
        require(rounded <= type(uint8).max, "sqrt cannot be packed");
        require(rounded != 0, "zeros in the table will cause failures in the algorithm");
        return uint8(rounded);
    }

    /**
     * @notice Format a `UD60x18` with 3 decimal places of precision.
     */
    function toString(UD60x18 value) private pure returns (string memory fmt) {
        string memory integer = vm.toString(convert(value));
        string memory frac = vm.toString(convert(value.frac() * convert(1000) + HALF_UNIT));

        bytes memory zeros = new bytes(3 - bytes(frac).length);
        for (uint8 i = 0; i < zeros.length; i++) {
            zeros[i] = "0";
        }
        return string.concat(integer, ".", string(zeros), frac);
    }

    /**
     * @notice Generate table of approximated `msb()` values for 3-bit indexing.
     */
    function makeTable() private pure returns (uint8[] memory table) {
        table = new uint8[](32);
        for (uint256 i = 0; i < 32; i++) {
            UD60x18 average = sqrtAverage(8 * i, 8 * (i + 1));
            uint8 packed = packRounded(average);
            console.log("%s: sqrt=%s, packed=%s", i, toString(average), vm.toString(abi.encodePacked(packed)));
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
