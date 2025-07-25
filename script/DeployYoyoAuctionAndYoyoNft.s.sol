// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoAuction} from "../src/YoyoAuction.sol";
import {YoyoNft, ConstructorParams} from "../src/YoyoNft.sol";

contract DeployYoyoAuctionAndYoyoNft is Script {
    struct DeployYoyoNftParams {
        string baseURI;
        address auctionContract;
    }

    string public constant BASE_URI = "https://example.com/api/metadata/";

    function run() public returns (YoyoAuction, YoyoNft) {
        vm.startBroadcast();

        // 1. Deploy YoyoAuction contract
        YoyoAuction yoyoAuction = new YoyoAuction();
        console.log("YoyoAuction deployed at:", address(yoyoAuction));

        // 2. Create constructor params
        ConstructorParams memory params = ConstructorParams({
            baseURI: BASE_URI,
            auctionContract: address(yoyoAuction)
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
