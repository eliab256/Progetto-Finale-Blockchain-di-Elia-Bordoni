// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNFT} from "../src/YoyoNFT.sol";

contract YoyoNftScript is Script {
    YoyoNFT public yoyoNFT;

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
