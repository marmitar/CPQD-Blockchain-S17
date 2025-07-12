// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { Test } from "forge-std/Test.sol";

import { TrabalhoERC20 } from "../src/Challenge1.sol";

contract Challenge1Test is Test {
    TrabalhoERC20 public erc20 = TrabalhoERC20(address(0));

    function setUp() public {
        erc20 = new TrabalhoERC20();
    }

    function test_Initialized() public view {
        assertNotEq(address(erc20), address(0));
    }
}
