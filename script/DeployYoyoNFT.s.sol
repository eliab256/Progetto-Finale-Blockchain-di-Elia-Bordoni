// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNFT} from "../src/YoyoNFT.sol";

contract YoyoNFTScript is Script {
    YoyoNFT public yoyoNFT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        yoyoNFT = new YoyoNFT();

        vm.stopBroadcast();
    }
}
