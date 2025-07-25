// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoAuction} from "../src/YoyoAuction.sol";
import {YoyoNft} from "../src/YoyoNft.sol";
import {DeployYoyoAuctionAndYoyoNft} from "../script/DeployYoyoAuctionAndYoyoNft.s.sol";

contract YoyoAuctionTest is Test {
    YoyoAuction public yoyoAuction;
    YoyoNft public yoyoNft;

    //Test Partecipants
    address public deployer;
    address public USER_1 = makeAddr("User1");
    address public USER_2 = makeAddr("User2");
    address public USER_NO_BALANCE = makeAddr("user no balance");

    uint256 public constant STARTING_BALANCE_YOYO_CONTRACT = 10 ether;
    uint256 public constant STARTING_BALANCE_AUCTION_CONTRACT = 10 ether;
    uint256 public constant STARTING_BALANCE_DEPLOYER = 10 ether;
    uint256 public constant STARTING_BALANCE_USER_1 = 10 ether;
    uint256 public constant STARTING_BALANCE_USER_2 = 10 ether;
    uint256 public constant STARTING_BALANCE_USER_NO_BALANCE = 0 ether;

    function setUp() public {
        DeployYoyoAuctionAndYoyoNft deployerScript = new DeployYoyoAuctionAndYoyoNft();
        (yoyoAuction, yoyoNft) = deployerScript.run();

        deployer = msg.sender;

        //Set up balances for each address
        vm.deal(deployer, STARTING_BALANCE_DEPLOYER);
        vm.deal(address(yoyoNft), STARTING_BALANCE_YOYO_CONTRACT);
        vm.deal(address(yoyoAuction), STARTING_BALANCE_AUCTION_CONTRACT);
        vm.deal(USER_1, STARTING_BALANCE_USER_1);
        vm.deal(USER_2, STARTING_BALANCE_USER_2);
        vm.deal(USER_NO_BALANCE, STARTING_BALANCE_USER_NO_BALANCE);
    }
}
