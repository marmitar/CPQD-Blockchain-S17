// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";

import { TrabalhoERC20 } from "../src/Challenge1.sol";

/**
 * @title Unit tests for the {TrabalhoERC20} contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Based on <https://github.com/transmissions11/solmate/blob/main/src/test/ERC20.t.sol>.
 */
contract Challenge1Test is Test {
    TrabalhoERC20 private hrc;

    /**
     * @dev Runs before each test case. Useful for cleaning up left-over state.
     */
    function setUp() external {
        hrc = new TrabalhoERC20();
    }

    /**
     * @notice Verifies that {TrabalhoERC20} implements the optional [ERC-20](https://eips.ethereum.org/EIPS/eip-20)
     * usability methods.
     */
    function invariant_HasOptionalMetadata() external {
        targetSender(hrc.THE_HEIR());

        assertEq(hrc.name(), "Heir Coin");
        assertEq(hrc.symbol(), "HRC");
        assertEq(hrc.decimals(), 0);
    }

    /**
     * @notice Total supply never changes for the Heir Coin.
     */
    function invariant_TotalSupply() external {
        targetSender(hrc.THE_HEIR());

        assertEq(hrc.totalSupply(), 1000);
    }

    /**
     * @notice Checks that {TrabalhoERC20} starts with all balances zeroed, except for {THE_HEIR}.
     */
    function testFuzz_InitialBalance(address account) external view {
        assertEq(hrc.balanceOf(account), account == hrc.THE_HEIR() ? 1000 : 0);
    }

    /**
     * @notice Checks that {TrabalhoERC20-approve} changes {TrabalhoERC20-allowance}.
     */
    function testFuzz_Approve(address spender, uint256 value) external {
        address owner = hrc.THE_HEIR();
        assertEq(hrc.allowance(owner, spender), 0);

        vm.prank(owner);
        hrc.approve(spender, value);

        assertEq(hrc.allowance(owner, spender), value);
    }

    /**
     * @notice Checks that {TrabalhoERC20-transfer} modifies {TrabalhoERC20-balanceOf}.
     */
    function testFuzz_Transfer(address to, uint16 amount) external {
        vm.assume(amount <= 1000);
        address owner = hrc.THE_HEIR();

        vm.prank(owner);
        assertTrue(hrc.transfer(to, amount));

        if (to == owner) {
            assertEq(hrc.balanceOf(owner), hrc.totalSupply());
        } else {
            assertEq(hrc.balanceOf(to), amount);
            assertEq(hrc.balanceOf(owner), hrc.totalSupply() - amount);
        }
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} changes {TrabalhoERC20-balanceOf} and {TrabalhoERC20-allowance}.
     */
    function testFuzz_TransferFrom(address to, uint16 approval, uint16 amount) external {
        vm.assume(amount <= approval && approval <= 1000);
        address owner = hrc.THE_HEIR();
        address spender = address(this);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval));

        assertTrue(hrc.transferFrom(owner, to, amount));
        assertEq(hrc.allowance(owner, spender), approval - amount);

        if (to == owner) {
            assertEq(hrc.balanceOf(owner), hrc.totalSupply());
            assertEq(hrc.balanceOf(spender), 0);
        } else {
            assertEq(hrc.balanceOf(to), amount);
            assertEq(hrc.balanceOf(owner), hrc.totalSupply() - amount);
        }
    }

    /**
     * @notice Checks that {TrabalhoERC20-transfer} fails when {TrabalhoERC20-balanceOf} is insufficient.
     */
    function testFuzz_FailTransferInsufficientBalance(address owner) external {
        uint256 initialBalance = owner == hrc.THE_HEIR() ? 1000 : 0;
        address to = address(this);
        uint256 amount = initialBalance + 1;
        vm.assume(to != owner);

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientBalance.selector, owner, initialBalance, amount)
        );
        vm.prank(owner);
        assertFalse(hrc.transfer(to, amount));

        assertEq(hrc.balanceOf(hrc.THE_HEIR()), hrc.totalSupply());
        assertEq(hrc.balanceOf(owner), initialBalance);
        assertEq(hrc.balanceOf(to), 0);
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} fails when {TrabalhoERC20-allowance} is insufficient.
     */
    function testFuzz_FailTransferFromInsufficientAllowance(address to, uint256 amount) external {
        vm.assume(amount > 0);
        address owner = hrc.THE_HEIR();
        address spender = address(this);
        uint256 approval = amount - 1;
        vm.assume(spender != owner);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval));

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientAllowance.selector, owner, spender, approval, amount)
        );
        assertFalse(hrc.transferFrom(owner, to, amount));
        assertEq(hrc.allowance(owner, spender), approval);

        assertEq(hrc.balanceOf(owner), hrc.totalSupply());
        assertEq(hrc.balanceOf(spender), 0);
        assertEq(hrc.balanceOf(to), to == hrc.THE_HEIR() ? hrc.totalSupply() : 0);
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} fails when {TrabalhoERC20-balanceOf} is insufficient.
     */
    function testFuzz_FailTransferFromInsufficientBalance(address to, uint256 amount) external {
        vm.assume(amount > 1000);
        address owner = hrc.THE_HEIR();
        address spender = address(this);
        uint256 approval = bound(amount, 0, type(uint256).max - 1) + 1;
        vm.assume(spender != owner);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval));

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientBalance.selector, owner, hrc.totalSupply(), amount)
        );
        assertFalse(hrc.transferFrom(owner, to, amount));
        assertEq(hrc.allowance(owner, spender), approval);

        assertEq(hrc.balanceOf(owner), hrc.totalSupply());
        assertEq(hrc.balanceOf(spender), 0);
        assertEq(hrc.balanceOf(to), to == hrc.THE_HEIR() ? hrc.totalSupply() : 0);
    }
}
