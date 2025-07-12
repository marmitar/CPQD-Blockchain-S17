// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";

import { TrabalhoERC20 } from "../src/Challenge1.sol";

/**
 * @title Unit tests for the `TrabalhoERC20` contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge1Test is Test {
    TrabalhoERC20 private mtx;

    /**
     * @dev Runs before each test case. Useful for cleaning up left-over state.
     */
    function setUp() public {
        mtx = new TrabalhoERC20();
    }

    /**
     * @notice Verifies that `TrabalhoERC20` implements the optional [ERC-20](https://eips.ethereum.org/EIPS/eip-20)
     * usability methods.
     */
    function test_HasOptionalMetadata() public view {
        assertEq(mtx.name(), "Marmitex");
        assertEq(mtx.symbol(), "MTX");
        assertEq(mtx.decimals(), 16);
    }

    /**
     * Checks that `TrabalhoERC20` starts with all balances zeroed.
     */
    function testFuzz_StartsEmpty(address account) public view {
        assertEq(mtx.balanceOf(account), 0);
        assertEq(mtx.totalSupply(), 0);
    }
}
