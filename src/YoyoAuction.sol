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
    error YoyoAuction__InvalidAuctionType();


    /* Type Declaration */
    enum AuctionState {
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
        uint256 auctionId;
        uint256 tokenId;
        address nftOwner;
        AuctionState state;
        AuctionType auctionType;
        uint256 startPrice;
        uint256 startTime;
        uint256 endTime;
        address higherBidder;
        uint256 higherBid;
        uint256 minimumBidIncrement; 
    }


    /* State variables */
    address private immutable i_owner;
    uint256 private s_minimumBidIncrement = 0.005 ether;
    uint256 private s_auctionDurationInHours = 24;
    uint256 private s_auctionCounter = 0;
    uint256 private s_multiplierBasicMintPrice = 5;

    mapping (uint256 => AuctionStruct) private s_auctionsFromAuctionId;


    /* Events */
    event YoyoAuction__AuctionInitialized(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        AuctionState indexed state,
        AuctionType auctionType,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 minimumBidIncrement
    );



    /* Modifiers */
    modifier onlyOwner() {
       if (msg.sender != i_owner) {
            revert YoyoAuction__NotOwner();
        }
        _;
    }

    /* Constructor */
    constructor(address _yoyoNftAddress) {
        i_owner = msg.sender;
        i_yoyoNftContract = IYoyoNFT(_yoyoNftAddress);
    }

    /* Functions */
       // Function to initialize an auction
    function initializeAuction(uint256 _tokenId, AuctionType _auctionType) external onlyOwner {
        if(i_yoyoNftContract.getIfTokenIdIsMintable(_tokenId) == false) {
            revert YoyoAuction__InvalidTokenId();
        }
        if(_auctionType == AuctionType.ENGLISH) {
            initializeEnglishAuction(_tokenId);
        } else if(_auctionType == AuctionType.DUTCH) {
            initializeDutchAuction(_tokenId);
        } else {
            revert YoyoAuction__InvalidAuctionType();
        }
    }

    function initializeEnglishAuction(uint256 _tokenId) internal {
        uint256 newAuctionId = s_auctionCounter++;
        uint256 startPrice = i_yoyoNftContract.getBasicMintPrice();
        uint256 endTime = block.timestamp + (s_auctionDurationInHours * 1 hours);

        s_auctionsFromAuctionId[newAuctionId] = AuctionStruct({
            auctionId: newAuctionId,
            tokenId: _tokenId,
            nftOwner: address(0),
            state: AuctionState.OPEN,
            auctionType: AuctionType.ENGLISH,
            startPrice: startPrice,
            startTime: block.timestamp,
            endTime: endTime,
            higherBidder: address(0),
            higherBid: 0,
            minimumBidIncrement: s_minimumBidIncrement
        });
        
        emit YoyoAuction__AuctionInitialized(
            newAuctionId,
            _tokenId,
            newAuction.state,
            newActtion.auctionType,
            newAuction.startPrice,
            newAuction.startTime,
            newAuction.endTime,
            newAuction.minimumBidIncrement
        );
    }

    function initializeDutchAuction(uint256 _tokenId) internal {
        uint256 newAuctionId = s_auctionCounter++;
        uint256 startPrice = i_yoyoNftContract.getBasicMintPrice() * s_multiplierBasicMintPrice;
        uint256 endTime = block.timestamp + (s_auctionDurationInHours * 1 hours);

        s_auctionsFromAuctionId[newAuctionId] = AuctionStruct({
            auctionId: newAuctionId,
            tokenId: _tokenId,
            nftOwner: address(0),
            state: AuctionState.OPEN,
            auctionType: AuctionType.DUTCH,
            startPrice: startPrice,
            startTime: block.timestamp,
            endTime: endTime,
            higherBidder: address(0),
            higherBid: 0,
            minimumBidIncrement: s_minimumBidIncrement
        });
        
        emit YoyoAuction__AuctionInitialized(
            newAuctionId,
            _tokenId,
            newAuction.state,
            newActtion.auctionType,
            newAuction.startPrice,
            newAuction.startTime,
            newAuction.endTime,
            newAuction.minimumBidIncrement
        );

    }
        // Function to place a bid on an auction
    function placeBid(uint256 _auctionId) external payable {}


        // Functions to change auction parameters
    function changeMinimumBidIncrement(uint256 _newIncrement) external onlyOwner {
        if(_newIncrement <= 0) {
            revert YoyoAuction__InvalidValue();
        }
        s_minimumBidIncrement = _newIncrement;
    }

    function changeAuctionDuration(uint256 _newDurationInHours) external onlyOwner {
        if(_newDurationInHours <= 0) {
            revert YoyoAuction__InvalidValue();
        }
        s_auctionDurationInHours = _newDurationInHours;
    }

    function changeMultiplierBasicMintPrice(uint256 _newMultiplier) external onlyOwner {
        if(_newMultiplier <= 1) {
            revert YoyoAuction__InvalidValue();
        }
        s_multiplierBasicMintPrice = _newMultiplier;
    }

    function getContractOwner() external view returns (address) {
        return i_owner;
    }

    function getNftContract() external view returns (address) {
        return address(i_yoyoNftContract);
    }

    function getAuctionFromAuctionId(uint256 _auctionId) public view returns (AuctionStruct memory) {
        return s_auctionsFromAuctionId[_auctionId];
    }


}
