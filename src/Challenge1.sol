// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

/**
 * @title Marmitex ERC-20 tokens.
 * @author Tiago de Paula Alves <tiagodepalves@gmail.com>
 * @notice Simple [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token implementation, which provides basic
 * functionality to transfer tokens, as well as allow tokens to be approved so they can be spent by another on-chain
 * third party.
 */
contract TrabalhoERC20 is IERC20 {
    /**
     * @notice The name of the Marmitex token.
     */
    string public name = "Marmitex";

    /**
     * @notice The symbol of the Marmitex token.
     */
    string public symbol = "MTX";

    /// forge-lint: disable-next-item(screaming-snake-case-immutable)
    /**
     * @notice The decimals places of the Marmitex token.
     */
    uint8 public immutable decimals = 16;

    /**
     * @dev Current amount of tokens assigned to each account.
     */
    mapping(address account => uint256) private _balance;

    /**
     * @dev All accounts that had a positive `balance` at some point.
     */
    address[] private _accounts;

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _accounts.length; i++) {
            total += _balance[_accounts[i]];
        }
        return total;
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {
        // returns 0 if `account` is not in `balance`
        return _balance[account];
    }

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
