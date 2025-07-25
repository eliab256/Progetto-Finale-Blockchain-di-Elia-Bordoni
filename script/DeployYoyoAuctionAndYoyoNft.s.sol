// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoAuction} from "../src/YoyoAuction.sol";
import {YoyoNft, ConstructorParams} from "../src/YoyoNft.sol";

contract DeployYoyoAuctionAndYoyoNft is Script {
    string public constant BASE_URI = "https://example.com/api/metadata/";
    uint256 public constant BASIC_MINT_PRICE = 0.01 ether;

    function run() public returns (YoyoAuction, YoyoNft) {
        vm.startBroadcast();

        // 1. Deploy YoyoAuction contract
        YoyoAuction yoyoAuction = new YoyoAuction();
        console.log("YoyoAuction deployed at:", address(yoyoAuction));

        // 2. Create constructor params
        ConstructorParams memory params = ConstructorParams({
            baseURI: BASE_URI,
            auctionContract: address(yoyoAuction),
            basicMintPrice: BASIC_MINT_PRICE
        });

        // 3. Deploy the NFT contract
        YoyoNft yoyoNft = new YoyoNft(params);
        console.log("YoyoNft deployed at:", address(yoyoNft));

        // 4. Set the YoyoNft contract address inside YoyoAuction
        yoyoAuction.setNftContract(address(yoyoNft));
        console.log(
            "YoyoNft contract set in YoyoAuction at:",
            address(yoyoAuction.getNftContract())
        );

        vm.stopBroadcast();

        return (yoyoAuction, yoyoNft);
    }
}
