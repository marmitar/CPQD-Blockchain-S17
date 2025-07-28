// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";

import { Sqrt } from "../src/gist/Sqrt.sol";

contract Gist is Script {
    uint256 private transient count;
    uint256 private transient totalGas;
    uint256 private transient minGas;
    uint256 private transient maxGas;

    modifier testCase(string memory testName) {
        count = 0;
        totalGas = 0;
        minGas = type(uint256).max;
        maxGas = 0;
        _;
        displayResults(testName);
    }

    function displayResults(string memory testName) private view {
        string memory avg = vm.toString(totalGas / count);
        string memory avgD = vm.toString((10 * (totalGas % count)) / count);

        console.log("===== %s =====", testName);
        console.log("minimum = %s", vm.toString(minGas));
        console.log("average = %s ", string.concat(avg, ".", avgD));
        console.log("maximum = %s", vm.toString(maxGas));
        console.log();
    }

    function assertIsRoot(uint256 x, uint256 root) private pure {
        vm.assertLe(root ** 2, x, "square root too big");
        if (x != type(uint256).max) {
            vm.assertGt((root + 1) ** 2, x, "square root too small");
        } else {
            vm.assertEq(root, type(uint128).max, "wrong square root for UINT256_MAX");
        }
    }

    Sqrt private immutable IT = new Sqrt();

    function test(uint256 x) private {
        vm.resumeGasMetering();
        uint256 startGas = gasleft();
        uint256 root = IT.sqrt(x);
        uint256 endGas = gasleft();
        vm.pauseGasMetering();
        uint256 gasUsed = startGas - endGas - 2;

        assertIsRoot(x, root);
        count += 1;
        totalGas += gasUsed;
        if (gasUsed < minGas) {
            minGas = gasUsed;
        }
        if (gasUsed > maxGas) {
            maxGas = gasUsed;
        }
    }

    function testUint8() private testCase("all 8-bit numbers") {
        for (uint256 i = 0; i <= type(uint8).max; i++) {
            test(i);
        }
    }

    function testUint16() private testCase("all 16-bit numbers") {
        for (uint256 i = 0; i <= type(uint16).max; i++) {
            test(i);
        }
    }

    function testPow2() private testCase("all powers of two") {
        for (uint256 i = 0; i < 256; i++) {
            uint256 pi = 2 ** i;
            test(pi);
        }
    }

    function testAlmostPow2() private testCase("almost powers of two") {
        for (uint256 i = 0; i < 256; i++) {
            uint256 pi = 2 ** i;
            test(pi - 1);
        }
    }

    uint256 internal immutable RUNS = vm.envOr("RUNS", uint256(2) ** 18);

    function testRandom() private testCase("randomized values") {
        bytes32 seed = 0x7567739e3d73e54878217ee501bbb9b2fe749ab61c88280f86ae58b39b3017a0;
        for (uint256 i = 0; i < RUNS; i++) {
            uint256 x = uint256(keccak256(abi.encode(seed, i)));
            test(x);
        }
    }

    function run() external noGasMetering {
        testUint8();
        testUint16();
        testPow2();
        testAlmostPow2();
        testRandom();
    }
}
