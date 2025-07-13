// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IYoyoNFT} from "./IYoyoNFT.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title 
 * @author Elia Bordoni
 * @notice
 * @dev
 */

contract YoyoAuction is ReentrancyGuard {
    IYoyoNFT public immutable i_yoyoNftContract;

    /* Errors */
    error YoyoAuction__NotOwner();
    error YoyoAuction__InvalidAddress();
    error YoyoAuction__InvalidTokenId();
    error YoyoAuction__InvalidValue();


    /* Type Declaration */
    enum AuctionState {
        CREATED,
        OPEN, 
        PAUSED,
        CLOSED,
        FINALIZED 
    }

    enum AuctionType {
        ENGLISH,
        DUTCH
    }

    struct AuctionStruct {
        uint256 tokenId;
        address owner;
        AuctionState state;
        AuctionType auctionType;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
    }


    /* State variables */
    address private immutable i_owner;


    /* Events */




    /* Modifiers */
    modifier onlyOwner() {
       if (msg.sender != i_owner) {
            revert YoyoAuction__NotOwner();
        }
        _;
    }

    modifier onlyValidAuctionType(AuctionType _auctionType) {
        if(_auctionType != AuctionType.ENGLISH && _auctionType != AuctionType.DUTCH) {
            revert YoyoAuction__InvalidValue();
        }
        _;
    }

    /* Constructor */
    constructor(address _yoyoNftAddress) {
        i_owner = msg.sender;
        i_yoyoNftContract = IYoyoNFT(_yoyoNftAddress);
    }

    /* Functions */
    function initializeAuction(uint256 _tokenId, AuctionType _auctionType) external onlyOwner onlyValidAuctionType(_auctionType) {
        if(i_yoyoNftContract.getIfTokenIdIsMintable(_tokenId) == false) {
            revert YoyoAuction__InvalidTokenId();
        }
        if(_auctionType == AuctionType.ENGLISH) {
            initializeEnglishAuction(_tokenId);
        } else if(_auctionType == AuctionType.DUTCH) {
            initializeDutchAuction(_tokenId);
        }
    }

    function initializeEnglishAuction(uint256 _tokenId) internal {}
    function initializeDutchAuction(uint256 _tokenId) internal {}


}
