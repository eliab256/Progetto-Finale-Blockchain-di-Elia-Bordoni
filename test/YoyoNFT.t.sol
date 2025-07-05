// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNft.sol";

contract YoyoNftTest is Test {
    YoyoNft public yoyoNft;

    function setUp() public {
        yoyoNft = new YoyoNft();
    }
}
