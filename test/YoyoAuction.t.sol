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

    function testIfPlaceBidOnAuctionPlaceBidOnEnglishAuction() public {
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
                YoyoAuction.AuctionState.CLOSED
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

    function testIfChangeMintPriceWorksWhileCurrentAuctionIsNotOpen() public {
        uint256 newPrice = 0.1 ether;
        vm.startPrank(deployer);
        yoyoAuction.changeMintPrice(newPrice);
        vm.stopPrank();

        assertEq(yoyoNft.getBasicMintPrice(), newPrice);
    }
}
