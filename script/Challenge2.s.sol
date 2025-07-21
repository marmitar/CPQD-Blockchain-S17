// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.27;

import { Script, console } from "forge-std/Script.sol";
import { mulDiv } from "prb-math/Common.sol";

/**
 * @title Calculate approximate fractions of π.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @dev Run with `forge script script/Challenge2.s.sol:PiFractionScript`.
 */
contract PiFractionScript is Script {
    // forgefmt: disable-next-item
    /**
     * @notice Largest decimal representation of π with 256 bits.
     * @dev Taken from <https://www.piday.org/million/>.
     */
    uint256 private constant PI = 3_1415926535897932384626433832795028841971693993751058209749445923078164062862;

    // forgefmt: disable-next-item
    /**
     * @notice Decimal base for {PI} in 256 bits.
     */
    uint256 private constant BASE = 1_0000000000000000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Calculates `x / π` in 256 bits.
     */
    function divPi(uint256 x) private pure returns (uint256 xOverPi) {
        return mulDiv(x, BASE, PI);
    }

    /**
     * @notice Area of a circle of radius `r` assuming `p / q` is a good approximation of π.
     */
    function circleArea(uint256 p, uint256 q, uint256 r) private pure returns (uint256 area) {
        unchecked {
            return ((p * r * r) + (q / 2)) / q;
        }
    }

    /**
     * @notice Find a fraction `numerator / denominator ≈ π` such that `circleArea(maxRadius)` does not overflow,
     * but `circleArea(maxRadius + 1)` does.
     */
    function findPiFraction(uint256 maxRadius) private pure returns (uint256 numerator, uint256 denominator) {
        uint256 areaMax = circleArea(PI / maxRadius ** 2, BASE / maxRadius ** 2, maxRadius);
        console.log("maxRadius = %d, area(maxRadius) = %d", maxRadius, areaMax);
        uint256 areaAfterMax = circleArea(PI / (maxRadius + 1) ** 2, BASE / (maxRadius + 1) ** 2, maxRadius + 1);
        console.log("maxRadius+1 = %d, area(maxRadius+1) = %d", maxRadius + 1, areaAfterMax);

        uint256 p = type(uint256).max;
        uint256 i = 0;
        while (true) {
            uint256 q = divPi(p);
            console.log("[%d] p = %x, q = %x", i, p, q);

            uint256 a1 = circleArea(p, q, maxRadius);
            uint256 a2 = circleArea(p, q, maxRadius + 1);
            console.log("[%d] area(p, q, maxRadius) = %d, area(p, q, maxRadius+1) = %d", i, a1, a2);
            if (a1 == areaMax && a2 != areaAfterMax) {
                return (p, q);
            }

            uint256 next = ~(q / 2) / (maxRadius + 1) ** 2;
            require(next != p, "A good fraction could not be found");
            p = next;
            i++;
        }
    }

    /**
     * @notice Maximum input for the radius specified in Challenge 2.
     */
    uint16 public constant MAX_R = 65_535;

    /**
     * @notice Find good approximation of π for the required bounds.
     */
    function run() external pure returns (bytes32 numerator, bytes32 denominator, bytes32 offset) {
        (uint256 p, uint256 q) = findPiFraction(MAX_R);

        require(circleArea(p, q, MAX_R) == 13_492_625_933, "area(MAX_R) is wrong");
        require(circleArea(p, q, uint256(MAX_R) + 1) < 13_492_625_933, "area(MAX_R+1) does not overflow");
        return (bytes32(p), bytes32(q), bytes32(q / 2));
    }
}
