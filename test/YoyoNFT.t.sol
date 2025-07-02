// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNFT} from "../src/YoyoNFT.sol";

contract YoyoNFTTest is Test {
    YoyoNFT public yoyoNFT;

    function setUp() public {
        yoyoNFT = new YoyoNFT();
    }
}
