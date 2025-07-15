// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

/**
 * @title Heir Coins, implemented as ERC-20 tokens.
 * @author Tiago de Paula Alves <tiagodepalves@gmail.com>
 * @notice Simple [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token implementation, which provides basic
 * functionality to transfer tokens, as well as allow tokens to be approved so they can be spent by another on-chain
 * third party.
 */
contract TrabalhoERC20 is IERC20 {
    /**
     * @notice He who owns it all.
     */
    address public constant THE_HEIR = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

    /// forge-lint: disable-next-item(screaming-snake-case-const)
    /**
     * @notice The name of the Heir Coin.
     */
    string public constant name = "Heir Coin";

    /// forge-lint: disable-next-item(screaming-snake-case-const)
    /**
     * @notice The symbol of the Heir Coin.
     */
    string public constant symbol = "HRC";

    /// forge-lint: disable-next-item(screaming-snake-case-const)
    /**
     * @notice The decimals places of the Heir Coin, which is none, because the coin is absolute.
     */
    uint8 public constant decimals = 0;

    /// forge-lint: disable-next-item(screaming-snake-case-const)
    /**
     * @notice The amount of tokens in existence, which should be 1000.
     */
    uint256 public constant totalSupply = 1000;

    /**
     * @dev The `account` index in the `_balance` array.
     */
    mapping(address account => uint256 amount) private _balance;

    /**
     * @notice Start the heraldry.
     */
    constructor() {
        _balance[THE_HEIR] = totalSupply;
        emit Transfer(address(0), THE_HEIR, totalSupply);
    }

    /**
     * @notice Owner doesn't have enough balance to complete the transaction.
     */
    error InsufficientBalance(address owner, uint256 balance, uint256 required);

    /**
     * @notice Spender is not allowed to transfer the required funds from owner.
     */
    error InsufficientAllowance(address owner, address spender, uint256 allowance, uint256 required);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256 balance) {
        return _balance[account];
    }

    /**
     * @dev Internal {transferFrom} implementation. Allowance unchecked, only `_balance` is verified. Returns `true`
     * if the transfer was made, or `false` if the balance is not sufficient.
     */
    function _transfer(address from, address to, uint256 amount) private {
        uint256 balanceFrom = _balance[from];
        require(balanceFrom >= amount, InsufficientBalance(from, balanceFrom, amount));

        unchecked {
            // SAFETY: can't underflow, already checked
            _balance[from] = balanceFrom - amount;
            // SAFETY: can never go beyond 1000
            _balance[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `to`.
     * @dev Triggers a {IERC20-Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev How many tokens of each `owner` are assigned to each `spender`.
     */
    mapping(address owner => mapping(address spender => uint256 amount)) private _allowed;

    /**
     * @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism `amount` is then deducted from
     * the caller's allowance.
     * @dev Triggers a {IERC20-Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        uint256 allowed = _allowed[from][msg.sender];
        require(allowed >= amount, InsufficientAllowance(from, msg.sender, allowed, amount));

        _transfer(from, to, amount);
        unchecked {
            // SAFETY: can't underflow, already checked
            _allowed[from][msg.sender] = allowed - amount;
        }
        return true;
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @dev Triggers an {IERC20-Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool success) {
        _allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining) {
        return _allowed[owner][spender];
    }
}
