// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNft.sol";

contract YoyoNftScript is Script {
    YoyoNft public yoyoNft;

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
