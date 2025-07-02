// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNFT} from "../src/YoyoNFT.sol";

contract YoyoNFTTest is Test {
    YoyoNFT public yoyoNFT;

    function setUp() public {
        yoyoNFT = new YoyoNFT();
    }
}
