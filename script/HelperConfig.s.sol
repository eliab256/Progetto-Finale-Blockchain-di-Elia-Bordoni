// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

abstract contract CodeConstant {
    //Chain Ids
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;

    //Mocks Inputs
}

contract HelperConfig is Script, CodeConstant {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address account;
        string baseURI;
        address auctionContract;
        string name;
        string symbol;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        //add here values from ENV file
        //     networkConfigs[SEPOLIA_CHAIN_ID] = NetworkConfig({
        // });
    }

    // function getConfigsByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
    //     if(networkConfigs[_chainId].account == address(0)){
    //         revert HelperConfig__InvalidChainId();
    //     }
    // }
}
