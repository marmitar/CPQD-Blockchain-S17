// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

/**
 * @title Simple [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token implementation.
 * @author Tiago de Paula Alves <tiagodepalves@gmail.com>
 * @notice Provides basic functionality to transfer tokens, as well as allow tokens to be approved so they can be spent
 * by another on-chain third party.
 */
contract TrabalhoERC20 is IERC20 {
    /**
     * @notice Returns the name of the token.
     */
    function name() external view returns (string memory) { }

    /**
     * @notice Returns the symbol of the token.
     */
    function symbol() external view returns (string memory) { }

    /**
     * @notice Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8) { }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) { }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) { }

    /**
     * @notice Moves `amount` tokens from the caller's account to `to`.
     * @dev Triggers a `Transfer` event.
     */
    function transfer(address to, uint256 amount) external returns (bool) { }

    /**
     * @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism `amount` is then deducted from
     * the caller's allowance.
     * @dev Triggers a `Transfer` event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) { }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @dev Triggers an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool) { }

    /**
     * @notice Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256) { }
}
