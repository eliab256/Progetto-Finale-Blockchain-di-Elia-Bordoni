// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {YoyoNft, ConstructorParams} from "../src/YoyoNft.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract YoyoNftTest is Test {
    YoyoNft public yoyoNft;

    string public constant BASE_URI_EXAMPLE =
        "https://example.com/api/metadata/";

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
        deployer = msg.sender;

        ConstructorParams memory params = ConstructorParams({
            baseURI: BASE_URI_EXAMPLE,
            auctionContract: address(AUCTION_CONTRACT)
        });

        vm.startPrank(deployer);
        yoyoNft = new YoyoNft(params);

        //Set up balances for each address
        vm.deal(deployer, STARTING_BALANCE_DEPLOYER);
        vm.deal(address(yoyoNft), STARTING_BALANCE_YOYO_CONTRACT);
        vm.deal(AUCTION_CONTRACT, STARTING_BALANCE_AUCTION_CONTRACT);
        vm.deal(USER_1, STARTING_BALANCE_USER_1);
        vm.deal(USER_2, STARTING_BALANCE_USER_2);
        vm.deal(USER_NO_BALANCE, STARTING_BALANCE_USER_NO_BALANCE);

        vm.stopPrank();

        //partecipants address consoleLog
        console2.log("Deployer Address: ", deployer);
        console2.log("YoyoNft Contract Address: ", address(yoyoNft));
        console2.log("Auction Contract Address: ", AUCTION_CONTRACT);
        console2.log("User 1 Address: ", USER_1);
        console2.log("User 2 Address: ", USER_2);
        console2.log("User No Balance Address: ", USER_NO_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
            Test the constructor parameters assignments
    //////////////////////////////////////////////////////////////*/
    function testNameAndSymbol() public {
        string memory expectedName = "Yoyo Collection";
        string memory expectedSymbol = "YOYO";

        assertEq(yoyoNft.name(), expectedName);
        assertEq(yoyoNft.symbol(), expectedSymbol);
    }

    function testContructorParameters() public {
        assertEq(yoyoNft.getAuctionContract(), AUCTION_CONTRACT);
        assertEq(yoyoNft.getBaseURI(), BASE_URI_EXAMPLE);
        assertEq(yoyoNft.getContractOwner(), deployer);
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    function testIfDeployRevertDueToZeroBaseURI() public {
        ConstructorParams memory params = ConstructorParams({
            baseURI: "",
            auctionContract: AUCTION_CONTRACT
        });
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        new YoyoNft(params);
    }

    function testIfDeployRevertDueToInvalidAuctionContract() public {
        ConstructorParams memory params = ConstructorParams({
            baseURI: BASE_URI_EXAMPLE,
            auctionContract: address(0)
        });
        vm.expectRevert(YoyoNft.YoyoNft__InvalidAddress.selector);
        new YoyoNft(params);
    }

    /*//////////////////////////////////////////////////////////////
            Test receive and fallback functions
    //////////////////////////////////////////////////////////////*/
    function testIfReceiveFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__ThisContractDoesntAcceptDeposit.selector
        );
        address(yoyoNft).call{value: 1 ether}("");
    }

    function testIfFallbackFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__CallValidFunctionToInteractWithContract.selector
        );
        address(yoyoNft).call{value: 1 ether}("metadata");
    }

    /*//////////////////////////////////////////////////////////////
                        Test modifiers
    //////////////////////////////////////////////////////////////*/
    function testIfYoyoOnlyOwnerModifierWorks() public {
        vm.expectRevert(YoyoNft.YoyoNft__NotOwner.selector);
        vm.prank(USER_1);
        yoyoNft.withdraw();
    }

    function testIfYoyoOnlyAuctionContractModifierWorks() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);

        vm.expectRevert(YoyoNft.YoyoNft__NotAuctionContract.selector);
        vm.prank(USER_1);
        yoyoNft.mintNft{value: 1 ether}(recipient, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                Test deposit and withdraw functions  
    //////////////////////////////////////////////////////////////*/

    function testIfDepositWorksAndEmitsEvent() public {
        uint256 depositAmount = 0.001 ether;

        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__DepositCompleted(depositAmount, block.timestamp);
        yoyoNft.deposit{value: depositAmount}();
        assertEq(
            address(yoyoNft).balance - STARTING_BALANCE_YOYO_CONTRACT,
            depositAmount
        );
    }

    function testIfDepositRevertsIfValueIsZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        yoyoNft.deposit{value: 0}();
    }

    function testIfWithdrawWorksAndEmitsEvent() public {
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__WithdrawCompleted(
            STARTING_BALANCE_YOYO_CONTRACT,
            block.timestamp
        );
        yoyoNft.withdraw();
        assertEq(address(yoyoNft).balance, 0);
        assertEq(
            deployer.balance,
            STARTING_BALANCE_DEPLOYER + STARTING_BALANCE_YOYO_CONTRACT
        );
    }

    function testIfWithdrawRevertsIfContractBalanceIsZero() public {
        vm.deal(address(yoyoNft), 0);
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ContractBalanceIsZero.selector);
        yoyoNft.withdraw();
    }

    /*//////////////////////////////////////////////////////////////
                Test mintPrice functions 
    //////////////////////////////////////////////////////////////*/

    function testIfSetBasicMintPriceRevertsifPriceIsZero() public {
        vm.prank(yoyoNft.getAuctionContract());
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        yoyoNft.setBasicMintPrice(0);
    }

    function testIfsetBasicMintPriceWorksAndEmitsEvent() public {
        uint256 newPrice = 0.003 ether;

        vm.prank(yoyoNft.getAuctionContract());
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__MintPriceUpdated(newPrice, block.timestamp);
        yoyoNft.setBasicMintPrice(newPrice);

        assertEq(yoyoNft.getBasicMintPrice(), newPrice);
    }

    /*//////////////////////////////////////////////////////////////
                Test mint NFT function
    //////////////////////////////////////////////////////////////*/
    function testIfMintNftWorksAndEmitsEvent() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);
        emit YoyoNft.YoyoNft__NftMinted(
            recipient,
            tokenId,
            yoyoNft.tokenURI(tokenId),
            block.timestamp
        );

        assertEq(yoyoNft.ownerOf(tokenId), recipient);
    }

    function testIfMintNftUpdatesTotalMinted() public {
        uint256 tokenId = 1;
        uint256 secondTokenId = 2;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);
        assertEq(yoyoNft.getTotalMinted(), 1);

        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, secondTokenId);
        assertEq(yoyoNft.getTotalMinted(), 2);
    }

    function testIfMintNftRevertsIfNotEnoughEthSent() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT);
        vm.expectRevert(YoyoNft.YoyoNft__NotEnoughEtherSent.selector);
        yoyoNft.mintNft{value: mintPrice - 0.00001 ether}(recipient, tokenId);
    }

    function testIfMintNftRevertsIfNftIsAlreadyMinted() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT); //first mint
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        vm.prank(AUCTION_CONTRACT); //try to mint again same tokenId
        vm.expectRevert(YoyoNft.YoyoNft__NftAlreadyMinted.selector);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);
    }

    function testIfNftMintRevertsIfRecipientIsZeroAddress() public {
        uint256 tokenId = 1;
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT);
        vm.expectRevert(YoyoNft.YoyoNft__InvalidAddress.selector);
        yoyoNft.mintNft{value: mintPrice}(address(0), tokenId);
    }

    function testIfMintNftRevertsDueToInvalidTokenId() public {
        uint256 invalidTokenId = yoyoNft.MAX_NFT_SUPPLY(); // This is an invalid tokenId
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        vm.prank(AUCTION_CONTRACT);
        vm.expectRevert(YoyoNft.YoyoNft__TokenIdDoesNotExist.selector);
        yoyoNft.mintNft{value: mintPrice}(recipient, invalidTokenId);
    }

    function testIfMintNftRevertsIfMaxSupplyReached() public {
        uint256 mintPrice = yoyoNft.getBasicMintPrice();
        // Mint all NFTs to reach max supply
        for (uint256 i = 0; i < yoyoNft.MAX_NFT_SUPPLY(); i++) {
            vm.prank(AUCTION_CONTRACT);
            yoyoNft.mintNft{value: mintPrice}(address(USER_1), i);
        }

        uint256 tokenId = 1;
        address recipient = address(USER_2);

        vm.expectRevert(YoyoNft.YoyoNft__NftMaxSupplyReached.selector);
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                Test transfer NFT function
    //////////////////////////////////////////////////////////////*/
    function testIfTransferNftWorksAndEmitsEvent() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(address(USER_1), tokenId);

        vm.prank(USER_1);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__NftTransferred(
            USER_1,
            recipient,
            tokenId,
            block.timestamp
        );
        yoyoNft.transferNft(recipient, tokenId);

        assertEq(yoyoNft.ownerOf(tokenId), recipient);
    }

    function testIfTransferNftRevertsIfToAddressIsZero() public {
        uint256 tokenId = 1;
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(address(USER_1), tokenId);

        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__InvalidAddress.selector);
        yoyoNft.transferNft(address(0), tokenId);
    }

    function testIfTransferNftRevertsIfNotOwnerCallFunction() public {
        uint256 tokenId = 1;
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(address(USER_1), tokenId);

        vm.prank(USER_2);
        vm.expectRevert(YoyoNft.YoyoNft__NotOwner.selector);
        yoyoNft.transferNft(USER_NO_BALANCE, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                Test getters functions
    //////////////////////////////////////////////////////////////*/
    function testTokenURIRevertsIfTokenIdDoesNotExist() public {
        uint256 invalidTokenId = yoyoNft.MAX_NFT_SUPPLY(); // This is an invalid tokenId

        vm.expectRevert(YoyoNft.YoyoNft__TokenIdDoesNotExist.selector);
        yoyoNft.tokenURI(invalidTokenId);
    }

    function testTokenURIRevertsIfTokenIdNotMinted() public {
        uint256 tokenId = 1;

        vm.expectRevert(YoyoNft.YoyoNft__NftNotMinted.selector);
        yoyoNft.tokenURI(tokenId);
    }

    function testTokenURIReturnsCorrectURI() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        string memory expectedURI = string(
            abi.encodePacked(
                BASE_URI_EXAMPLE,
                "/",
                Strings.toString(tokenId),
                ".json"
            )
        );

        assertEq(yoyoNft.tokenURI(tokenId), expectedURI);
    }

    function testGetBaseURI() public {
        assertEq(yoyoNft.getBaseURI(), BASE_URI_EXAMPLE);
    }

    function testGetTotalMinted() public {
        assertEq(yoyoNft.getTotalMinted(), 0);

        uint256 tokenId = 5;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        assertEq(yoyoNft.getTotalMinted(), 1);
    }

    function testGetOwnerFromTokenId() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        assertEq(yoyoNft.getOwnerFromTokenId(tokenId), recipient);
    }

    function testGetAccountBalance() public {
        assertEq(yoyoNft.getAccountBalance(USER_1), 0);

        uint256 tokenId = 1;
        address recipient = address(USER_1);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        assertEq(yoyoNft.getAccountBalance(USER_1), 1);
    }

    function testGetContractOwner() public {
        assertEq(yoyoNft.getContractOwner(), deployer);
    }

    function testGetAuctionContract() public {
        assertEq(yoyoNft.getAuctionContract(), AUCTION_CONTRACT);
    }

    function testGetBasicMintPrice() public {
        uint256 newPrice = 0.003 ether;
        vm.prank(yoyoNft.getAuctionContract());
        yoyoNft.setBasicMintPrice(newPrice);
        assertEq(yoyoNft.getBasicMintPrice(), newPrice);
    }

    function testIfGetIfTokenIdIsMintableReturnTrueIfMintable() public {
        uint256 tokenId = 5; //Id of non minted token
        assertEq(yoyoNft.getIfTokenIdIsMintable(tokenId), true);
    }

    function testIfGetIfTokenIdIsMintableReturnFalseIfTokenAlreadyMinted()
        public
    {
        uint256 tokenId = 5;
        address recipient = address(USER_2);
        uint256 mintPrice = yoyoNft.getBasicMintPrice();

        // Mint the NFT first
        vm.prank(AUCTION_CONTRACT);
        yoyoNft.mintNft{value: mintPrice}(recipient, tokenId);

        //Assert token five is not mintable
        assertEq(yoyoNft.getIfTokenIdIsMintable(tokenId), false);
    }

    function testIfGetIfTokenIdIsMintableReturnFalseIfTokenIdIsOutOfCollection()
        public
    {
        //create a tokenId out of nft supply
        uint256 tokenId = yoyoNft.MAX_NFT_SUPPLY() + 1;

        //Assert token five is not mintable
        assertEq(yoyoNft.getIfTokenIdIsMintable(tokenId), false);
    }
}
