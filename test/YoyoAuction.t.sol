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

    function testIfDeployAuctionContractAssignOwnerAndAuctionCounter() public {
        assertEq(yoyoAuction.getContractOwner(), deployer);
        assertEq(yoyoAuction.getAuctionCounter(), 0);
    }

    function testIfDeployNftContractAssignOwnerAndAuctionContract() public {
        assertEq(yoyoNft.getContractOwner(), deployer);
        assertEq(yoyoAuction.getContractOwner(), deployer);
        assertEq(yoyoNft.getAuctionContract(), address(yoyoAuction));
        assertEq(yoyoAuction.getNftContract(), address(yoyoNft));
    }

    function testIfReceiveFunctionReverts() public {
        vm.expectRevert(
            YoyoAuction.YoyoAuction__ThisContractDoesntAcceptDeposit.selector
        );
        address(yoyoNft).call{value: 1 ether}("");
    }

    function testIfFallbackFunctionReverts() public {
        vm.expectRevert(
            YoyoAuction
                .YoyoAuction__CallValidFunctionToInteractWithContract
                .selector
        );
        address(yoyoNft).call{value: 1 ether}("metadata");
    }

    function testIfOpenNewAuctionRevertsIfNotOwner() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__NotOwner.selector);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();
    }

    function testIfOpenNewAuctionRevertDueToNftContractNotSet() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        vm.startPrank(deployer);
        YoyoAuction yoyoAuctionWithoutNft = new YoyoAuction();

        vm.expectRevert(YoyoAuction.YoyoAuction__NftContractNotSet.selector);
        yoyoAuctionWithoutNft.openNewAuction(tokenId, auctionType);
        vm.stopPrank();
    }

    function testIfOpenNewAuctionWorks() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 startPrice = yoyoNft.getBasicMintPrice();
        uint256 auctionDuration = yoyoAuction.getAuctionDurationInHours() *
            1 hours;

        uint256 initialAuctionCounter = yoyoAuction.getAuctionCounter();

        uint256 fakeTimestamp = block.timestamp + 1 days;
        vm.warp(fakeTimestamp);

        vm.startPrank(deployer);
        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__AuctionOpened(
            initialAuctionCounter + 1,
            tokenId,
            auctionType,
            startPrice,
            fakeTimestamp,
            fakeTimestamp + auctionDuration,
            startPrice / 20
        );

        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionCounter(), initialAuctionCounter + 1);
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).tokenId, tokenId);
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).auctionType ==
                YoyoAuction.AuctionType.ENGLISH
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).startTime,
            fakeTimestamp
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).endTime,
            fakeTimestamp + auctionDuration
        );
    }
}
