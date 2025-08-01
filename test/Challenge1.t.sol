// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
/// forge-lint: disable-next-item(unused-import)
import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { TrabalhoERC20 } from "../src/Challenge1.sol";

/**
 * @title Unit tests for the {TrabalhoERC20} contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Based on <https://github.com/transmissions11/solmate/blob/main/src/test/ERC20.t.sol>.
 */
contract Challenge1Test is Test {
    TrabalhoERC20 private hrc;

    /**
     * @notice Runs before each test case. Useful for cleaning up left-over state.
     */
    function setUp() external {
        vm.expectEmit(1);
        emit IERC20.Transfer(address(0), 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955, 1000);

        hrc = new TrabalhoERC20();
    }

    /**
     * @notice Verifies that {TrabalhoERC20} implements the optional [ERC-20](https://eips.ethereum.org/EIPS/eip-20)
     * usability methods.
     */
    function invariant_HasOptionalMetadata() external {
        targetSender(hrc.THE_HEIR());

        assertEq(hrc.name(), "Heir Coin", "name()");
        assertEq(hrc.symbol(), "HRC", "symbol()");
        assertEq(hrc.decimals(), 0, "decimals()");
    }

    /**
     * @notice Total supply never changes for the Heir Coin.
     */
    function invariant_TotalSupply() external {
        targetSender(hrc.THE_HEIR());

        assertEq(hrc.totalSupply(), 1000, "totalSupply()");
    }

    /**
     * @notice Checks that {TrabalhoERC20} starts with all balances zeroed, except for {THE_HEIR}.
     */
    function testFuzz_InitialBalance(address account) external view {
        assertEq(hrc.balanceOf(account), account == hrc.THE_HEIR() ? 1000 : 0, "balanceOf()");
    }

    /**
     * @notice Checks that {TrabalhoERC20-approve} changes {TrabalhoERC20-allowance}.
     */
    function testFuzz_Approve(address spender, uint256 value) external {
        address owner = hrc.THE_HEIR();
        assertEq(hrc.allowance(owner, spender), 0, "allowance()");

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Approval(owner, spender, value);

        vm.prank(owner);
        hrc.approve(spender, value);

        assertEq(hrc.allowance(owner, spender), value, "allowance()");
    }

    /**
     * @notice Checks that {TrabalhoERC20-transfer} modifies {TrabalhoERC20-balanceOf}.
     */
    function testFuzz_Transfer(address to, uint16 amount) external {
        vm.assume(amount <= 1000);
        address owner = hrc.THE_HEIR();

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Transfer(owner, to, amount);

        vm.prank(owner);
        assertTrue(hrc.transfer(to, amount), "transfer()");

        if (to == owner) {
            assertEq(hrc.balanceOf(owner), hrc.totalSupply(), "balanceOf(owner)");
        } else {
            assertEq(hrc.balanceOf(to), amount, "balanceOf(to)");
            assertEq(hrc.balanceOf(owner), hrc.totalSupply() - amount, "balanceOf(owner)");
        }
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} changes {TrabalhoERC20-balanceOf} and {TrabalhoERC20-allowance}.
     */
    function testFuzz_TransferFrom(address to, uint16 approval, uint16 amount) external {
        vm.assume(amount <= approval && approval <= 1000);
        address owner = hrc.THE_HEIR();
        address spender = address(this);

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Approval(owner, spender, approval);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval), "approve()");

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Transfer(owner, to, amount);

        assertTrue(hrc.transferFrom(owner, to, amount), "transferFrom()");
        assertEq(hrc.allowance(owner, spender), approval - amount, "allowance()");

        if (to == owner) {
            assertEq(hrc.balanceOf(owner), hrc.totalSupply(), "balanceOf(owner)");
            assertEq(hrc.balanceOf(spender), 0, "balanceOf(spender)");
        } else {
            assertEq(hrc.balanceOf(to), amount, "balanceOf(to)");
            assertEq(hrc.balanceOf(owner), hrc.totalSupply() - amount, "balanceOf(owner)");
        }
    }

    /**
     * @notice Checks that {TrabalhoERC20-transfer} fails when {TrabalhoERC20-balanceOf} is insufficient.
     */
    function testFuzz_RevertIf_TransferInsufficientBalance(address owner) external {
        uint256 initialBalance = owner == hrc.THE_HEIR() ? 1000 : 0;
        address to = address(this);
        uint256 amount = initialBalance + 1;
        vm.assume(to != owner);

        vm.expectEmit(address(hrc), 0);
        emit IERC20.Transfer(owner, to, amount);

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientBalance.selector, owner, initialBalance, amount)
        );
        vm.prank(owner);
        assertFalse(hrc.transfer(to, amount), "revert InsufficientBalance");

        assertEq(hrc.balanceOf(hrc.THE_HEIR()), hrc.totalSupply(), "balanceOf(THE_HEIR)");
        assertEq(hrc.balanceOf(owner), initialBalance, "balanceOf(owner)");
        assertEq(hrc.balanceOf(to), 0, "balanceOf(to)");
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} fails when {TrabalhoERC20-allowance} is insufficient.
     */
    function testFuzz_RevertIf_TransferFromInsufficientAllowance(address to, uint256 amount) external {
        vm.assume(amount > 0);
        address owner = hrc.THE_HEIR();
        address spender = address(this);
        uint256 approval = amount - 1;
        vm.assume(spender != owner);

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Approval(owner, spender, approval);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval), "approve()");

        vm.expectEmit(address(hrc), 0);
        emit IERC20.Transfer(owner, to, amount);

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientAllowance.selector, owner, spender, approval, amount)
        );
        assertFalse(hrc.transferFrom(owner, to, amount), "revert InsufficientAllowance");
        assertEq(hrc.allowance(owner, spender), approval, "allowance()");

        assertEq(hrc.balanceOf(owner), hrc.totalSupply(), "balanceOf(owner)");
        assertEq(hrc.balanceOf(spender), 0, "balanceOf(spender)");
        assertEq(hrc.balanceOf(to), to == hrc.THE_HEIR() ? hrc.totalSupply() : 0, "balanceOf(to)");
    }

    /**
     * @notice Checks that {TrabalhoERC20-transferFrom} fails when {TrabalhoERC20-balanceOf} is insufficient.
     */
    function testFuzz_RevertIf_TransferFromInsufficientBalance(address to, uint256 amount) external {
        vm.assume(amount > 1000);
        address owner = hrc.THE_HEIR();
        address spender = address(this);
        uint256 approval = bound(amount, 0, type(uint256).max - 1) + 1;
        vm.assume(spender != owner);

        vm.expectEmit(address(hrc), 1);
        emit IERC20.Approval(owner, spender, approval);

        vm.prank(owner);
        assertTrue(hrc.approve(spender, approval), "approve()");

        vm.expectEmit(address(hrc), 0);
        emit IERC20.Transfer(owner, to, amount);

        vm.expectRevert(
            abi.encodeWithSelector(TrabalhoERC20.InsufficientBalance.selector, owner, hrc.totalSupply(), amount)
        );
        assertFalse(hrc.transferFrom(owner, to, amount), "revert InsufficientBalance");
        assertEq(hrc.allowance(owner, spender), approval, "allowance()");

        assertEq(hrc.balanceOf(owner), hrc.totalSupply(), "balanceOf(owner)");
        assertEq(hrc.balanceOf(spender), 0, "balanceOf(spender)");
        assertEq(hrc.balanceOf(to), to == hrc.THE_HEIR() ? hrc.totalSupply() : 0, "balanceOf(to)");
    }
}
