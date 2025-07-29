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
     * @notice Pack the value of a square root of a `uint8` in a byte with the highest precision possible.
     */
    function packSqrt256Bits(UD60x18 sqrtValue) private pure returns (bytes1 packed) {
        UD60x18 base = convert(256).sqrt();
        uint256 rounded = convert(sqrtValue * base + HALF_UNIT);
        require(rounded <= type(uint8).max, "sqrt cannot be packed");
        require(rounded != 0, "zeros in the table will fail");
        return bytes1(uint8(rounded));
    }

    /**
     * @notice Generate the lookup table of precomputed square roots.
     */
    function run() external pure returns (bytes32 table) {
        for (uint256 i = 0; i < 32; i++) {
            UD60x18 average = sqrtAverage(8 * i, 8 * (i + 1));
            bytes1 packed = packSqrt256Bits(average);
            console.log("%s: average=%s, packed=%s", i, convert(average), uint8(packed));
            table |= bytes32(packed) >> 8 * i;
        }
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
