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
    uint256[] private _balance;

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _balance.length; i++) {
            total += _balance[i];
        }
        return total;
    }

    /**
     * @dev The `account` index in the `_balance` array.
     */
    mapping(address account => uint256 index) private _index;

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256 balance) {
        uint256 idx = _index[account];
        return idx > 0 ? _balance[idx - 1] : 0;
    }

    /**
     * @dev Recover the registered `_index` of `account`, if any, or create a new one with `_balance` zero.
     */
    function _registeredIndex(address account) private returns (uint256 index) {
        uint256 idx = _index[account];
        if (idx <= 0) {
            _balance.push(0);
            idx = _balance.length;
            _index[account] = idx;
        }
        return idx - 1;
    }

    /**
     * @dev Internal {transferFrom} implementation. Allowance unchecked, only `_balance` is verified. Returns `true`
     * if the transfer was made, or `false` if the balance is not sufficient.
     */
    function _transfer(address from, address to, uint256 amount) private returns (bool success) {
        uint256 indexFrom = _index[from];
        if (indexFrom <= 0 || _balance[indexFrom - 1] < amount) {
            return false;
        }

        _balance[indexFrom] -= amount;
        _balance[_registeredIndex(to)] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `to`.
     * @dev Triggers a {IERC20-Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool success) {
        return _transfer(msg.sender, to, amount);
    }

    /**
     * @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism `amount` is then deducted from
     * the caller's allowance.
     * @dev Triggers a {IERC20-Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        // TODO: check allowance
        return _transfer(from, to, amount);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @dev Triggers an {IERC20-Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool success) { }

    /**
     * @notice Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256) { }
}
