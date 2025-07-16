// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

/**
 * @title Reference implementation of the Integer Square Root.
 * @author Tiago de Paula Alves <tiagodepalves@gmail.com>
 */
contract Challenge3 {
    /**
     * @notice Implementation based on
     * [Heron's method](https://en.wikipedia.org/wiki/Square_root_algorithms#Heron's_method).
     */
    function isqrtH(uint256 n) external pure returns (uint256 root) {
        if (n <= 1) {
            return n;
        }

        uint256 x = n / 2;
        while (true) {
            uint256 xt = (x + n / x) / 2;
            if (xt >= x) {
                return x;
            } else {
                x = xt;
            }
        }
    }
}
