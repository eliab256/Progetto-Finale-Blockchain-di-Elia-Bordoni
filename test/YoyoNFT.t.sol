// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig, CodeConstant} from "../script/HelperConfig.s.sol";

contract YoyoNftTest is Test, CodeConstant {
    YoyoNft public yoyoNft;
    HelperConfig public helperConfig;

    //Test Partecipants
    address public deployer;
    address public AUCTION_CONTRACT = makeAddr("AuctionContract");
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
        yoyoNft = new YoyoNft(
            YoyoNft.ConstructorParams({
                baseURI: "https://example.com/api/metadata/",
                auctionContract: address(AUCTION_CONTRACT)
            })
        );

        deployer = msg.sender;

        //Set up balances for each address
        vm.deal(deployer, STARTING_BALANCE_DEPLOYER);
        vm.deal(address(yoyoNft), STARTING_BALANCE_YOYO_CONTRACT);
        vm.deal(AUCTION_CONTRACT, STARTING_BALANCE_AUCTION_CONTRACT);
        vm.deal(USER_1, STARTING_BALANCE_USER_1);
        vm.deal(USER_2, STARTING_BALANCE_USER_2);
        vm.deal(USER_NO_BALANCE, STARTING_BALANCE_USER_NO_BALANCE);

        //partecipants address consoleLog
        console2.log("Deployer Address: ", deployer);
        console2.log("YoyoNft Contract Address: ", address(yoyoNft));
        console2.log("Auction Contract Address: ", AUCTION_CONTRACT);
        console2.log("User 1 Address: ", USER_1);
        console2.log("User 2 Address: ", USER_2);
        console2.log("User No Balance Address: ", USER_NO_BALANCE);
    }
}
