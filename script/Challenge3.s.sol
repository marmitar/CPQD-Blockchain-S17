// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import "../src/Challenge3.sol" as YUL;

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
    function run(uint256 x) external pure returns (uint256 root) {
        return YUL.sqrt(x);
    }
}
