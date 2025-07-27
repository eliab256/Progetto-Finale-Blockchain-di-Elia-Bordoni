// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoAuction} from "../src/YoyoAuction.sol";
import {YoyoNft, ConstructorParams} from "../src/YoyoNft.sol";
import {YoyoNftMockFailingMint} from "./Mocks/YoyoNftMockFailingMint.sol";
import {RevertOnReceiverMock} from "./Mocks/RevertOnReceiverMock.sol";
import {DeployYoyoAuctionAndYoyoNft} from "../script/DeployYoyoAuctionAndYoyoNft.s.sol";

//Il mock serve per testare i casi in cui si prova a inserire valori non validi dentro le enum
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

    function testIfSetNftContractRevertsIfNotOwner() public {
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__NotOwner.selector);
        yoyoAuction.setNftContract(address(yoyoNft));
        vm.stopPrank();
    }

    function testIfSetNftContractRevertsIfAlreadySet() public {
        vm.startPrank(deployer);
        vm.expectRevert(
            YoyoAuction.YoyoAuction__NftContractAlreadySet.selector
        );
        yoyoAuction.setNftContract(address(yoyoNft));
        vm.stopPrank();
    }

    //test fsllbsck and receive functions
    function testIfReceiveFunctionReverts() public {
        vm.expectRevert(
            YoyoAuction.YoyoAuction__ThisContractDoesntAcceptDeposit.selector
        );
        address(yoyoAuction).call{value: 1 ether}("");
    }

    function testIfFallbackFunctionReverts() public {
        vm.expectRevert(
            YoyoAuction
                .YoyoAuction__CallValidFunctionToInteractWithContract
                .selector
        );
        address(yoyoAuction).call{value: 1 ether}("metadata");
    }

    //Test checkUpkeep
    function testPerformeUpkeepCanOnlyRunIfCheckUpkeepReturnsTrue() public {
        vm.prank(deployer);
        yoyoAuction.openNewAuction(1, YoyoAuction.AuctionType.ENGLISH);

        uint256 endTime = yoyoAuction.getAuctionFromAuctionId(1).endTime;
        uint256 auctionId = yoyoAuction.getAuctionFromAuctionId(1).auctionId;
        bytes memory performDataTest = abi.encode(auctionId);

        (bool upkeepNeeded, bytes memory performData) = yoyoAuction.checkUpkeep(
            ""
        );
        assertFalse(upkeepNeeded);
        assertEq(performDataTest, performData);

        vm.roll(block.number + 1);
        vm.warp(endTime);

        (upkeepNeeded, ) = yoyoAuction.checkUpkeep("");
        assertTrue(upkeepNeeded);
        assertEq(performDataTest, performData);
    }

    function testIfPerformUpkeepRevertsIfUpkeepNeededIsFalse() public {
        vm.prank(deployer);
        yoyoAuction.openNewAuction(1, YoyoAuction.AuctionType.ENGLISH);

        uint256 auctionId = yoyoAuction.getAuctionFromAuctionId(1).auctionId;
        bytes memory performDataTest = abi.encode(auctionId);

        vm.expectRevert(YoyoAuction.YoyoAuction__UpkeepNotNeeded.selector);
        yoyoAuction.performUpkeep(performDataTest);
    }

    function testIfPerformUpkeepCallCloseAuctionIfBidderIsNotZeroAddress()
        public
    {
        //Open New Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(1, YoyoAuction.AuctionType.ENGLISH);

        uint256 endTime = yoyoAuction.getAuctionFromAuctionId(1).endTime;
        uint256 auctionId = yoyoAuction.getAuctionFromAuctionId(1).auctionId;
        uint256 tokenId = yoyoAuction.getAuctionFromAuctionId(1).tokenId;
        uint256 startPrice = yoyoAuction.getAuctionFromAuctionId(1).startPrice;
        uint256 startTime = yoyoAuction.getAuctionFromAuctionId(1).startTime;
        bytes memory performDataTest = abi.encode(auctionId);
        uint256 bidAmount = yoyoAuction.getAuctionFromAuctionId(1).higherBid +
            yoyoAuction.getMinimumBidChangeAmount();

        vm.roll(block.number + 1);
        vm.warp(endTime - 1 hours);

        //Place a Bid
        vm.startPrank(USER_1);
        yoyoAuction.placeBidOnAuction{value: bidAmount}(1);
        vm.stopPrank();

        vm.roll(block.number + 1);
        vm.warp(endTime);

        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__AuctionClosed(
            auctionId,
            tokenId,
            startPrice,
            startTime,
            endTime,
            USER_1,
            bidAmount
        );

        yoyoAuction.performUpkeep(performDataTest);

        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.FINALIZED
        );
    }

    function testIfPerformUpkeepCallRestartEnglishAuctionCorrectlyIfBidderIsZeroAddress()
        public
    {
        //Open New Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(1, YoyoAuction.AuctionType.ENGLISH);

        uint256 endTime = yoyoAuction.getAuctionFromAuctionId(1).endTime;
        uint256 auctionId = yoyoAuction.getAuctionFromAuctionId(1).auctionId;
        uint256 tokenId = yoyoAuction.getAuctionFromAuctionId(1).tokenId;
        uint256 startPrice = yoyoAuction.getAuctionFromAuctionId(1).startPrice;
        uint256 oldStartTime = yoyoAuction.getAuctionFromAuctionId(1).startTime;
        bytes memory performDataTest = abi.encode(auctionId);

        vm.roll(block.number + 1);
        vm.warp(endTime);

        uint256 newStartTime = block.timestamp;
        uint256 newEndTime = newStartTime +
            yoyoAuction.getAuctionDurationInHours() *
            1 hours;

        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__AuctionRestarted(
            auctionId,
            tokenId,
            newStartTime,
            startPrice,
            newEndTime,
            yoyoAuction.getMinimumBidChangeAmount()
        );

        yoyoAuction.performUpkeep(performDataTest);

        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.OPEN
        );
        assertTrue(oldStartTime < newStartTime);
    }

    function testIfPerformUpkeepCallRestartDutchAuctionCorrectlyIfBidderIsZeroAddress()
        public
    {
        //Open New Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(1, YoyoAuction.AuctionType.DUTCH);

        uint256 endTime = yoyoAuction.getAuctionFromAuctionId(1).endTime;
        uint256 auctionId = yoyoAuction.getAuctionFromAuctionId(1).auctionId;
        uint256 tokenId = yoyoAuction.getAuctionFromAuctionId(1).tokenId;
        uint256 startPrice = yoyoAuction.getAuctionFromAuctionId(1).startPrice;
        uint256 oldStartTime = yoyoAuction.getAuctionFromAuctionId(1).startTime;
        bytes memory performDataTest = abi.encode(auctionId);

        vm.roll(block.number + 1);
        vm.warp(endTime);

        uint256 newStartTime = block.timestamp;
        uint256 newEndTime = newStartTime +
            yoyoAuction.getAuctionDurationInHours() *
            1 hours;

        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__AuctionRestarted(
            auctionId,
            tokenId,
            newStartTime,
            startPrice,
            newEndTime,
            yoyoAuction.getMinimumBidChangeAmount()
        );

        yoyoAuction.performUpkeep(performDataTest);

        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.OPEN
        );
        assertTrue(oldStartTime < newStartTime);
    }

    //Test Open New Auction
    function testIfOpenNewAuctionRevertsIfNotOwner() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__NotOwner.selector);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();
    }

    function testIfOpenNewAuctionRevertsDueToNftContractNotSet() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        vm.startPrank(deployer);
        YoyoAuction yoyoAuctionWithoutNft = new YoyoAuction();

        vm.expectRevert(YoyoAuction.YoyoAuction__NftContractNotSet.selector);
        yoyoAuctionWithoutNft.openNewAuction(tokenId, auctionType);
        vm.stopPrank();
    }

    function testIfOpenNewAuctionRevertsIfTokenIdIsNotMintable() public {
        uint256 tokenId = yoyoNft.MAX_NFT_SUPPLY() + 1; // Token ID that does not exist
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;

        vm.startPrank(deployer);
        vm.expectRevert(YoyoAuction.YoyoAuction__InvalidTokenId.selector);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();
    }

    function testIfOpenNewAuctionRevertsIfThereIsAlreadyAnAuctionOpen() public {
        uint256 tokenId = 1;
        uint256 secondTokenId = 2;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;

        vm.roll(1);
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);

        vm.roll(20);
        vm.startPrank(deployer);
        vm.expectRevert(YoyoAuction.YoyoAuction__AuctionStillOpen.selector);
        yoyoAuction.openNewAuction(secondTokenId, auctionType);
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

    function testIfOpenNewAuctionOpensNewEnglishAuction() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 startPrice = yoyoNft.getBasicMintPrice();
        uint256 auctionDuration = yoyoAuction.getAuctionDurationInHours() *
            1 hours;

        uint256 initialAuctionCounter = yoyoAuction.getAuctionCounter();

        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionCounter(), initialAuctionCounter + 1);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).auctionId,
            initialAuctionCounter + 1
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).tokenId, tokenId);
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).nftOwner, address(0));
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.OPEN
        );
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).auctionType ==
                YoyoAuction.AuctionType.ENGLISH
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).startPrice, startPrice);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).startTime,
            block.timestamp
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).endTime,
            block.timestamp + auctionDuration
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).higherBidder,
            address(0)
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBid, startPrice);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).minimumBidChangeAmount,
            startPrice / 40
        );
    }

    function testIfOpenNewAuctionOpnesNewDutchAuction() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;
        uint256 startPrice = yoyoNft.getBasicMintPrice() *
            yoyoAuction.getDutchAuctionStartPriceMultiplier();
        uint256 auctionDuration = yoyoAuction.getAuctionDurationInHours() *
            1 hours;
        uint256 dropAmount = (startPrice - yoyoNft.getBasicMintPrice()) / 48; //48 is s_dutchAuctionNumberOfIntervals
        uint256 initialAuctionCounter = yoyoAuction.getAuctionCounter();
        uint256 fakeTimestamp = block.timestamp + 1 days;
        vm.warp(fakeTimestamp);

        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionCounter(), initialAuctionCounter + 1);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).auctionId,
            initialAuctionCounter + 1
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).tokenId, tokenId);
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).nftOwner, address(0));
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.OPEN
        );
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).auctionType ==
                YoyoAuction.AuctionType.DUTCH
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).startPrice, startPrice);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).startTime,
            fakeTimestamp
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).endTime,
            fakeTimestamp + auctionDuration
        );
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).higherBidder,
            address(0)
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBid, startPrice);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).minimumBidChangeAmount,
            dropAmount
        );
    }

    //Test Place Bid
    function testIfPlaceBidOnAuctionRevertsIfDoesNotExist() public {
        uint256 invalidAuctionId = 10;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__AuctionDoesNotExist.selector);
        yoyoAuction.placeBidOnAuction{value: 0.1 ether}(invalidAuctionId);
        vm.stopPrank();
    }

    function testIfPlaceBidOnAuctionRevertsIfAuctionIsNotOpen() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        //Open New Dutch Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        uint256 currentAuctionPrice = yoyoAuction
            .getAuctionFromAuctionId(1)
            .higherBid;
        //Place a bid to close the auction
        vm.prank(USER_1);
        yoyoAuction.placeBidOnAuction{value: currentAuctionPrice}(1);

        //Try to place a bid on the same auction after it has been closed
        vm.startPrank(USER_2);
        vm.expectRevert(YoyoAuction.YoyoAuction__AuctionNotOpen.selector);
        yoyoAuction.placeBidOnAuction{value: currentAuctionPrice}(1);
        vm.stopPrank();
    }

    function testIfPlaceBidOnAuctionPlaceBidOnEnglishAuctionWorks() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 newBidPlaced = yoyoNft.getBasicMintPrice() +
            yoyoAuction.getMinimumBidChangeAmount();

        //Open New English Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        //Place a bid on the auction
        vm.startPrank(USER_1);
        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__BidPlaced(
            1,
            USER_1,
            newBidPlaced,
            auctionType
        );
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBidder, USER_1);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).higherBid,
            newBidPlaced
        );
        //if auction is English, should stay open after a bid is placed
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.OPEN
        );
    }

    function testIfPlaceBidOnEnglishAuctionRevertsIfBidTooLowAndHigherBidUpdateCorrectly()
        public
    {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 newBidPlaced = yoyoNft.getBasicMintPrice() +
            yoyoAuction.getMinimumBidChangeAmount();

        //Open New English Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        //place first bid on the auction
        vm.startPrank(USER_1);
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        //Try to place a bid that is too low
        vm.startPrank(USER_2);
        vm.expectRevert(YoyoAuction.YoyoAuction__BidTooLow.selector);
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBidder, USER_1);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).higherBid,
            newBidPlaced
        );
    }

    function testIfPlaceBidOnEnglishAuctionRefundsPreviousBidder() public {
        uint256 user1InitialBalance = USER_1.balance;
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 firstBid = yoyoNft.getBasicMintPrice() +
            yoyoAuction.getMinimumBidChangeAmount();
        uint256 secondBid = firstBid + yoyoAuction.getMinimumBidChangeAmount();

        //Open New English Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        //Place first bid on the auction
        vm.startPrank(USER_1);
        yoyoAuction.placeBidOnAuction{value: firstBid}(1);
        vm.stopPrank();

        uint256 user1BalanceAfterFirstBid = USER_1.balance;

        //Place second bid on the auction
        vm.startPrank(USER_2);
        vm.expectEmit(false, false, true, true);
        emit YoyoAuction.YoyoAuction__BidderRefunded(USER_1, firstBid, 1);
        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__BidPlaced(
            1,
            USER_2,
            secondBid,
            auctionType
        );
        yoyoAuction.placeBidOnAuction{value: secondBid}(1);
        vm.stopPrank();

        uint256 user1balanceAfterRefund = USER_1.balance;

        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBidder, USER_2);
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBid, secondBid);
        assertEq(user1BalanceAfterFirstBid, user1InitialBalance - firstBid);
        assertEq(user1InitialBalance, user1balanceAfterRefund);
    }

    function testIfPlaceBidOnDutchAuctionWorksAndCloseTheCurrentAuction()
        public
    {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;
        uint256 newBidPlaced = yoyoNft.getBasicMintPrice() *
            yoyoAuction.getDutchAuctionStartPriceMultiplier();

        //Open New Dutch Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        //Place a bid on the auction
        vm.startPrank(USER_1);
        vm.expectEmit(true, true, false, false);
        emit YoyoAuction.YoyoAuction__BidPlaced(
            1,
            USER_1,
            newBidPlaced,
            auctionType
        );
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        assertEq(yoyoAuction.getAuctionFromAuctionId(1).higherBidder, USER_1);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).higherBid,
            newBidPlaced
        );
        //if auction is Dutch, should close after a bid is placed
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.FINALIZED
        );
    }

    function testIfPlaceBidOnDutchAuctionRevertsIfBidTooLow() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        //Open New Dutch Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        uint256 newBidPlaced = yoyoAuction.getCurrentAuctionPrice() - 1;

        //place first bid on the auction
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__BidTooLow.selector);
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();
    }

    function testIfPlaceBidRevertDueToFailedRefund() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;

        //Open New English Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);

        YoyoAuction.AuctionStruct memory auction = yoyoAuction
            .getAuctionFromAuctionId(1);

        uint256 newBidPlaced = yoyoNft.getBasicMintPrice() +
            yoyoAuction.getMinimumBidChangeAmount();
        //Mock contract that will revert refund place a bid and become new higher bidder
        ConstructorParams memory params = ConstructorParams({
            baseURI: "https://example.com/api/metadata/",
            auctionContract: address(yoyoAuction),
            basicMintPrice: 0.01 ether
        });
        RevertOnReceiverMock revertOnReceiverMock = new RevertOnReceiverMock(
            params
        );
        revertOnReceiverMock.payAuctionContract{value: newBidPlaced}(
            payable(address(yoyoAuction)),
            auction.auctionId
        );

        //Place a new bid with user and try to refund the previous bidder
        vm.startPrank(USER_1);
        vm.expectRevert(
            YoyoAuction.YoyoAuction__PreviousBidderRefundFailed.selector
        );
        yoyoAuction.placeBidOnAuction{value: newBidPlaced * 2}(1);
    }

    //Test Close Auction Function
    function testIfCloseAuctionWorksWithDutchAuctionAndMintNft() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        //Open New Dutch Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        uint256 startTime = block.timestamp;
        uint256 startPrice = yoyoAuction.getCurrentAuctionPrice();
        vm.stopPrank();

        vm.roll(block.number + 1);
        vm.warp(yoyoAuction.getAuctionFromAuctionId(1).endTime - 4 hours);
        uint256 newBidPlaced = yoyoAuction.getCurrentAuctionPrice();

        //Place a bid on the auction
        vm.startPrank(USER_1);
        vm.expectEmit(true, true, true, true);
        emit YoyoAuction.YoyoAuction__AuctionClosed(
            1,
            tokenId,
            startPrice,
            startTime,
            block.timestamp,
            USER_1,
            newBidPlaced
        );
        vm.expectEmit(true, true, true, false);
        emit YoyoAuction.YoyoAuction__AuctionFinalized(1, tokenId, USER_1);
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        vm.roll(block.number + 1);

        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.FINALIZED
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).nftOwner, USER_1);
        assertEq(yoyoNft.ownerOf(tokenId), USER_1);
    }

    function testIfCloseAuctionWorksWithEnglishAuctionAndMintNft() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;

        //Open New English Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        uint256 startTime = block.timestamp;
        uint256 startPrice = yoyoNft.getBasicMintPrice();
        vm.stopPrank();

        vm.roll(block.number + 1);
        vm.warp(yoyoAuction.getAuctionFromAuctionId(1).endTime - 4 hours);
        uint256 newBidPlaced = yoyoNft.getBasicMintPrice() * 2;

        //Place a bid on the auction
        vm.startPrank(USER_1);
        yoyoAuction.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        vm.roll(block.number + 1);
        vm.warp(yoyoAuction.getAuctionFromAuctionId(1).endTime);
        //PerformUpkeep check conditions and call closeAuction function
        yoyoAuction.performUpkeep(abi.encode(1));

        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.FINALIZED
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).startTime, startTime);
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).startPrice, startPrice);
        assertEq(
            yoyoAuction.getAuctionFromAuctionId(1).endTime,
            block.timestamp
        );
        assertEq(yoyoAuction.getAuctionFromAuctionId(1).nftOwner, USER_1);
        assertEq(yoyoNft.ownerOf(tokenId), USER_1);
    }

    function testIfCloseAuctionFailMintWithoutErrorAndEmitEvents() public {
        //Deploy the mock contract
        YoyoNftMockFailingMint yoyoNftMockFailingMint = new YoyoNftMockFailingMint();
        //deploy new istance of YoyoAuction with the mock contract
        YoyoAuction yoyoAuctionWithMock = new YoyoAuction();
        yoyoAuctionWithMock.setNftContract(address(yoyoNftMockFailingMint));

        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        yoyoAuctionWithMock.openNewAuction(tokenId, auctionType);

        //Set Mock to fail mint
        string memory reasonEmpty = "";
        yoyoNftMockFailingMint.setShouldFailMint(true, reasonEmpty);

        //Place a Bid and trigger close auction
        vm.startPrank(USER_1);
        uint256 newBidPlaced = yoyoAuctionWithMock.getCurrentAuctionPrice();
        vm.expectEmit(true, true, true, true);
        emit YoyoAuction.YoyoAuction__AuctionClosed(
            1,
            tokenId,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startPrice,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startTime,
            block.timestamp,
            USER_1,
            newBidPlaced
        );
        vm.expectEmit(true, true, true, false);
        emit YoyoAuction.YoyoAuction__MintFailedLog(
            1,
            tokenId,
            USER_1,
            "unknown error"
        );
        yoyoAuctionWithMock.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        YoyoAuction.AuctionStruct memory currentAuction = yoyoAuctionWithMock
            .getAuctionFromAuctionId(1);
        assertTrue(currentAuction.state == YoyoAuction.AuctionState.CLOSED);
        assertEq(currentAuction.nftOwner, address(0));
    }

    function testIfCloseAuctionFailMintWithErrorAndEmitEvents() public {
        //Deploy the mock contract
        YoyoNftMockFailingMint yoyoNftMockFailingMint = new YoyoNftMockFailingMint();
        //deploy new istance of YoyoAuction with the mock contract
        YoyoAuction yoyoAuctionWithMock = new YoyoAuction();
        yoyoAuctionWithMock.setNftContract(address(yoyoNftMockFailingMint));

        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        yoyoAuctionWithMock.openNewAuction(tokenId, auctionType);

        //Set Mock to fail mint
        string memory reason = "mint failed";
        yoyoNftMockFailingMint.setShouldFailMint(true, reason);

        //Place a Bid and trigger close auction
        vm.startPrank(USER_1);
        uint256 newBidPlaced = yoyoAuctionWithMock.getCurrentAuctionPrice();
        vm.expectEmit(true, true, true, true);
        emit YoyoAuction.YoyoAuction__AuctionClosed(
            1,
            tokenId,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startPrice,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startTime,
            block.timestamp,
            USER_1,
            newBidPlaced
        );
        vm.expectEmit(true, true, true, false);
        emit YoyoAuction.YoyoAuction__MintFailedLog(1, tokenId, USER_1, reason);
        yoyoAuctionWithMock.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        YoyoAuction.AuctionStruct memory currentAuction = yoyoAuctionWithMock
            .getAuctionFromAuctionId(1);
        assertTrue(currentAuction.state == YoyoAuction.AuctionState.CLOSED);
        assertEq(currentAuction.nftOwner, address(0));
    }

    //Test manual mint function
    function testIfManulaMintCatchErrorWhenItFails() public {
        //Deploy the mock contract
        YoyoNftMockFailingMint yoyoNftMockFailingMint = new YoyoNftMockFailingMint();
        //deploy new istance of YoyoAuction with the mock contract
        YoyoAuction yoyoAuctionWithMock = new YoyoAuction();
        yoyoAuctionWithMock.setNftContract(address(yoyoNftMockFailingMint));

        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        yoyoAuctionWithMock.openNewAuction(tokenId, auctionType);

        //Set Mock to fail mint
        string memory reason = "mint failed";
        yoyoNftMockFailingMint.setShouldFailMint(true, reason);

        //Place a Bid and trigger close auction
        vm.startPrank(USER_1);
        uint256 newBidPlaced = yoyoAuctionWithMock.getCurrentAuctionPrice();
        vm.expectEmit(true, true, true, true);
        emit YoyoAuction.YoyoAuction__AuctionClosed(
            1,
            tokenId,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startPrice,
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).startTime,
            block.timestamp,
            USER_1,
            newBidPlaced
        );
        //Auction is closed but mint fails
        yoyoAuctionWithMock.placeBidOnAuction{value: newBidPlaced}(1);
        vm.stopPrank();

        YoyoAuction.AuctionStruct memory currentAuction = yoyoAuctionWithMock
            .getAuctionFromAuctionId(1);
        assertTrue(currentAuction.state == YoyoAuction.AuctionState.CLOSED);
        assertEq(currentAuction.nftOwner, address(0));

        //Try to manually mint the NFT
        vm.expectEmit(true, true, true, false);
        emit YoyoAuction.YoyoAuction__MintFailedLog(1, tokenId, USER_1, reason);
        yoyoAuctionWithMock.manualMintForWinner(1);

        assertTrue(
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).state ==
                YoyoAuction.AuctionState.CLOSED
        );
        assertEq(
            yoyoAuctionWithMock.getAuctionFromAuctionId(1).nftOwner,
            address(0)
        );
    }

    // function testIfManualMintWorksAfterMintFailed() public {
    //     //Deploy the mock contract
    //     YoyoNftMockFailingMint yoyoNftMockFailingMint = new YoyoNftMockFailingMint();
    //     //deploy new istance of YoyoAuction with the mock contract
    //     YoyoAuction yoyoAuctionWithMock = new YoyoAuction();
    //     yoyoAuctionWithMock.setNftContract(address(yoyoNftMockFailingMint));

    //     //Open New Auction
    //     uint256 tokenId = 5;
    //     YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;
    //     yoyoAuctionWithMock.openNewAuction(tokenId, auctionType);

    //     //Set Mock to fail mint
    //     string memory reason = "mint failed";
    //     yoyoNftMockFailingMint.setShouldFailMint(true, reason);

    //     //Place a Bid and trigger close auction
    //     vm.startPrank(USER_1);
    //     uint256 newBidPlaced = yoyoAuctionWithMock.getCurrentAuctionPrice();
    //     yoyoAuctionWithMock.placeBidOnAuction{value: newBidPlaced}(1);
    //     vm.stopPrank();

    //     //Assert Auction is closed but not finalized due to mint failure
    //     assertTrue(
    //         yoyoAuctionWithMock.getAuctionFromAuctionId(1).state ==
    //             YoyoAuction.AuctionState.CLOSED
    //     );

    //     //Set Mock to not fail mint
    //     yoyoNftMockFailingMint.setShouldFailMint(false, "");
    //     yoyoNftMockFailingMint.resetToken(tokenId);
    //     vm.roll(block.number + 1);
    //     vm.expectEmit(true, true, true, false);
    //     emit YoyoAuction.YoyoAuction__AuctionFinalized(1, tokenId, USER_1);
    //     yoyoAuctionWithMock.manualMintForWinner(1);
    //     assertTrue(
    //         yoyoAuctionWithMock.getAuctionFromAuctionId(1).state ==
    //             YoyoAuction.AuctionState.FINALIZED
    //     );
    //     assertEq(
    //         yoyoAuctionWithMock.getAuctionFromAuctionId(1).nftOwner,
    //         USER_1
    //     );
    // }

    function testIfManualMintRevertsIfNftContractNotSet() public {
        YoyoAuction yoyoAuctionWithoutNft = new YoyoAuction();

        vm.expectRevert(YoyoAuction.YoyoAuction__NftContractNotSet.selector);
        yoyoAuctionWithoutNft.manualMintForWinner(1);
    }

    function testIfManualMintRevertsIfNotOwner() public {
        vm.startPrank(USER_2);
        vm.expectRevert(YoyoAuction.YoyoAuction__NotOwner.selector);
        yoyoAuction.manualMintForWinner(1);
        vm.stopPrank();
    }

    function testIfManulaMintRevertsIfAuctionNotClosed() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;
        //Open New Dutch Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);

        vm.startPrank(deployer);
        vm.expectRevert(YoyoAuction.YoyoAuction__NoTokenToMint.selector);
        yoyoAuction.manualMintForWinner(1);
        vm.stopPrank();
    }

    function testIfManualMintRevertsDueToNftOwnerAlreadySet() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;

        //Open New Dutch Auction
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        uint256 bidAmount = yoyoAuction.getAuctionFromAuctionId(1).startPrice;

        //Place a bid to close the auction
        vm.prank(USER_1);
        yoyoAuction.placeBidOnAuction{value: bidAmount}(1);

        vm.startPrank(deployer);
        vm.expectRevert(YoyoAuction.YoyoAuction__NoTokenToMint.selector);
        yoyoAuction.manualMintForWinner(1);
        vm.stopPrank();
    }

    //Test Change Mint Price
    function testIfChangeMintPriceRevertsIfNotOwner() public {
        uint256 newPrice = 0.1 ether;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoAuction.YoyoAuction__NotOwner.selector);
        yoyoAuction.changeMintPrice(newPrice);
        vm.stopPrank();
    }

    function testIfChangeMintPriceRevertsDueToNftContractNotSet() public {
        uint256 newPrice = 0.1 ether;
        vm.startPrank(deployer);
        YoyoAuction yoyoAuctionWithoutNft = new YoyoAuction();

        vm.expectRevert(YoyoAuction.YoyoAuction__NftContractNotSet.selector);
        yoyoAuctionWithoutNft.changeMintPrice(newPrice);
        vm.stopPrank();
    }

    function testIfChangeMintPriceRevertsDueToNewPirceEqualToZero() public {
        uint256 newPrice = 0;
        vm.startPrank(deployer);
        vm.expectRevert(YoyoAuction.YoyoAuction__InvalidValue.selector);
        yoyoAuction.changeMintPrice(newPrice);
        vm.stopPrank();
    }

    function testIfChangeMintPriceRevertsWhileCurrentAuctionIsOpen() public {
        uint256 tokenId = 1;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        uint256 newPrice = 0.1 ether;

        //Open New English Auction
        vm.startPrank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);
        vm.stopPrank();

        vm.startPrank(deployer);
        vm.expectRevert(
            YoyoAuction
                .YoyoAuction__CannotChangeMintPriceDuringOpenAuction
                .selector
        );
        yoyoAuction.changeMintPrice(newPrice);
        vm.stopPrank();
    }

    function testIfChangeMintPriceWorksWhileCurrentAuctionIsNotOpen() public {
        uint256 newPrice = 0.1 ether;
        vm.startPrank(deployer);
        yoyoAuction.changeMintPrice(newPrice);
        vm.stopPrank();

        assertEq(yoyoNft.getBasicMintPrice(), newPrice);
    }

    //Test getters
    function testGetContractOwner() public {
        assertEq(yoyoAuction.getContractOwner(), deployer);
    }

    function testGetNftContract() public {
        assertEq(yoyoAuction.getNftContract(), address(yoyoNft));
    }

    function testGetAuctionCounterInitiallyZero() public {
        assertEq(yoyoAuction.getAuctionCounter(), 0);
    }

    function testGetAuctionDurationInHours() public {
        assertEq(yoyoAuction.getAuctionDurationInHours(), 24 hours);
    }

    function testGetMinimumBidChangeAmount() public {
        uint256 basicMintPrice = yoyoNft.getBasicMintPrice();
        assertEq(yoyoAuction.getMinimumBidChangeAmount(), basicMintPrice / 40);
    }

    function testGetDutchAuctionStartPriceMultiplier() public {
        assertEq(yoyoAuction.getDutchAuctionStartPriceMultiplier(), 13);
    }

    function testGetAuctionFromAuctionIdReturnsEmpty() public {
        yoyoAuction.getAuctionFromAuctionId(0);
        assertTrue(
            yoyoAuction.getAuctionFromAuctionId(0).state ==
                YoyoAuction.AuctionState.NOT_STARTED
        );
    }

    function testGetCurrentAuction() public {
        vm.prank(deployer);
        yoyoAuction.openNewAuction(5, YoyoAuction.AuctionType.ENGLISH);
        uint256 auctionCounter = yoyoAuction.getAuctionCounter();

        assertEq(yoyoAuction.getCurrentAuction().auctionId, auctionCounter);
    }

    function testIfGetCurrentAuctionPriceRevertsIfNoAuctionOpen() public {
        vm.expectRevert(YoyoAuction.YoyoAuction__AuctionNotOpen.selector);
        yoyoAuction.getCurrentAuctionPrice();
    }

    function testGetCurrentAuctionPriceOnEnglishAuction() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.ENGLISH;
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);

        uint256 minimumBidChangeAmountOfEnglishAuction = yoyoAuction
            .getAuctionFromAuctionId(1)
            .minimumBidChangeAmount;
        uint256 bidPlaced = 1 ether;

        vm.prank(USER_1);
        yoyoAuction.placeBidOnAuction{value: bidPlaced}(1);

        assertEq(
            yoyoAuction.getCurrentAuctionPrice(),
            bidPlaced + minimumBidChangeAmountOfEnglishAuction
        );
    }

    function testGetCurrentAuctionPriceOnDutchAuction() public {
        uint256 tokenId = 5;
        YoyoAuction.AuctionType auctionType = YoyoAuction.AuctionType.DUTCH;
        vm.prank(deployer);
        yoyoAuction.openNewAuction(tokenId, auctionType);

        uint256 startPrice = yoyoAuction.getAuctionFromAuctionId(1).startPrice;
        uint256 startTime = yoyoAuction.getAuctionFromAuctionId(1).startTime;
        uint256 endTime = yoyoAuction.getAuctionFromAuctionId(1).endTime;
        uint256 priceAtTheEnd = startPrice /
            yoyoAuction.getDutchAuctionStartPriceMultiplier();
        uint256 totalDrop = startPrice - priceAtTheEnd;

        vm.warp(startTime); // Warp to the start of the auction
        assertEq(yoyoAuction.getCurrentAuctionPrice(), startPrice);

        vm.warp(startTime + (endTime - startTime) / 2); // Warp to the middle of the auction
        uint256 currentAuctionPriceTest = startPrice - (totalDrop / 2);
        assertEq(yoyoAuction.getCurrentAuctionPrice(), currentAuctionPriceTest);

        vm.warp(endTime); // Warp to the end of the auction
        assertEq(yoyoAuction.getCurrentAuctionPrice(), priceAtTheEnd);
    }
}
