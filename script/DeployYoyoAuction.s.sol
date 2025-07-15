// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoAuction} from "../src/YoyoAuction.sol";

contract YoyoAuctionScript is Script {
    YoyoAuction public yoyoAuction;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        //yoyoAuction = new YoyoAuction();

        vm.stopBroadcast();
    }
}
