// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";

import { TrabalhoERC20 } from "../src/Challenge1.sol";

/**
 * @title Unit tests for the `TrabalhoERC20` contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract Challenge1Test is Test {
    TrabalhoERC20 private hrc;

    /**
     * @dev Runs before each test case. Useful for cleaning up left-over state.
     */
    function setUp() public {
        hrc = new TrabalhoERC20();
    }

    /**
     * @notice Verifies that `TrabalhoERC20` implements the optional [ERC-20](https://eips.ethereum.org/EIPS/eip-20)
     * usability methods.
     */
    function invariant_HasOptionalMetadata() public view {
        assertEq(hrc.name(), "Heir Coin");
        assertEq(hrc.symbol(), "HRC");
        assertEq(hrc.decimals(), 0);
    }

    /**
     * @notice Total supply never changes for the Heir Coin.
     */
    function invariant_TotalSupply() public view {
        assertEq(hrc.totalSupply(), 1000);
    }

    /**
     * Checks that `TrabalhoERC20` starts with all balances zeroed, except for {THE_HEIR}.
     */
    function testFuzz_InitialBalance(address account) public view {
        assertEq(hrc.balanceOf(account), account == hrc.THE_HEIR() ? 1000 : 0);
    }
}
