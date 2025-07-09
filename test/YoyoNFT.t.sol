// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig, CodeConstant} from "../script/HelperConfig.s.sol";

contract YoyoNftTest is Test, CodeConstant {
    YoyoNft public yoyoNft;
    HelperConfig public helperConfig;

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

        vm.startPrank(deployer);
        yoyoNft = new YoyoNft(
            YoyoNft.ConstructorParams({
                baseURI: BASE_URI_EXAMPLE,
                auctionContract: address(AUCTION_CONTRACT)
            })
        );

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
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        new YoyoNft(
            YoyoNft.ConstructorParams({
                baseURI: "",
                auctionContract: AUCTION_CONTRACT
            })
        );
    }

    function testIfDeployRevertDueToInvalidAuctionContract() public {
        vm.expectRevert(YoyoNft.YoyoNft__InvalidAddress.selector);
        new YoyoNft(
            YoyoNft.ConstructorParams({
                baseURI: BASE_URI_EXAMPLE,
                auctionContract: address(0)
            })
        );
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
        yoyoNft.setBasicMintPrice(0.002 ether);
    }

    function testIfYoyoOnlyAuctionContractModifierWorks() public {
        uint256 tokenId = 1;
        address recipient = address(USER_2);
        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__NotAuctionContract.selector);

        yoyoNft.mintNft{value: 1 ether}(recipient, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
            Test minting NFT function
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                Test deposit and withdraw functions  
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                Test mintPrice functions 
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                Test getters functions
    //////////////////////////////////////////////////////////////*/
}
