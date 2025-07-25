// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IYoyoNft} from "./IYoyoNft.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {YoyoDutchAuctionLibrary} from "./YoyoDutchAuctionLibrary.sol";

/**
 * @title
 * @author Elia Bordoni
 * @notice
 * @dev
 */

contract YoyoAuction is ReentrancyGuard, AutomationCompatibleInterface {
    IYoyoNft private yoyoNftContract;

    /* Errors */
    error YoyoAuction__NotOwner();
    error YoyoAuction__InvalidAddress();
    error YoyoAuction__ThisContractDoesntAcceptDeposit();
    error YoyoAuction__CallValidFunctionToInteractWithContract();
    error YoyoAuction__InvalidTokenId();
    error YoyoAuction__InvalidValue();
    error YoyoAuction__InvalidAuctionType();
    error YoyoAuction__AuctionNotOpen();
    error YoyoAuction__BidTooLow();
    error YoyoAuction__AuctionDoesNotExist();
    error YoyoAuction__PreviousBidderRefundFailed();
    error YoyoAuction__NoTokenToMint();
    error YoyoAuction__CannotChangeMintPriceDuringOpenAuction();
    error YoyoAuction__AuctionStillOpen();
    error YoyoAuction__UpkeepNotNeeded();
    error YoyoAuction__NftContractNotSet();
    error YoyoAuction__NftContractAlreadySet();

    /* Type Declaration */
    enum AuctionState {
        NOT_STARTED,
        OPEN,
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
        uint256 minimumBidChangeAmount;
    }

    /* State variables */
    address private immutable i_owner;
    uint256 private s_minimumBidChangeAmount;
    uint256 private s_auctionDurationInHours = 24 hours;
    uint256 private s_auctionCounter;
    uint256 private s_dutchAuctionDropNumberOfIntervals = 48;
    uint256 private s_dutchAuctionStartPriceMultiplier = 13;

    mapping(uint256 => AuctionStruct) internal s_auctionsFromAuctionId;

    /* Events */
    event YoyoAuction__BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        AuctionType auctionType
    );
    event YoyoAuction__BidderRefunded(
        address prevBidderAddress,
        uint256 bidAmount,
        uint256 indexed auctionId
    );
    event YoyoAuction__AuctionOpened(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        AuctionType auctionType,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 minimumBidIncrement
    );
    event YoyoAuction__AuctionRestarted(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 newStartTime,
        uint256 newStartPrice,
        uint256 newEndTime,
        uint256 minimumBidIncrement
    );
    event YoyoAuction__AuctionClosed(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime,
        address winner,
        uint256 indexed higherBid
    );
    event YoyoAuction__AuctionFinalized(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed nftOwner
    );
    event YoyoAuction__MintFailedLog(
        uint256 indexed auctionId,
        uint256 tokenId,
        address bidder,
        string reason
    );

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoAuction__NotOwner();
        }
        _;
    }

    /* Constructor */
    constructor() {
        i_owner = msg.sender;
        s_auctionCounter = 0;
    }

    function setNftContract(address _yoyoNftAddress) external onlyOwner {
        if (yoyoNftContract != IYoyoNft(address(0))) {
            revert YoyoAuction__NftContractAlreadySet();
        }
        yoyoNftContract = IYoyoNft(_yoyoNftAddress);
        s_minimumBidChangeAmount = yoyoNftContract.getBasicMintPrice() / 40; // 2,5% of the basic mint price
    }

    receive() external payable {
        revert YoyoAuction__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoAuction__CallValidFunctionToInteractWithContract();
    }

    /* Functions */
    function checkUpkeep(
        bytes calldata /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        AuctionStruct memory auction = s_auctionsFromAuctionId[
            s_auctionCounter
        ];
        bool auctionOpen = auction.state == AuctionState.OPEN;
        bool auctionEnded = block.timestamp >= auction.endTime;
        uint256 auctionId = auction.auctionId;

        upkeepNeeded = (auctionEnded && auctionOpen);
        performData = abi.encode(auctionId);
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded, ) = checkUpkeep(performData);
        if (!upkeepNeeded) {
            revert YoyoAuction__UpkeepNotNeeded();
        }
        uint256 auctionId = abi.decode(performData, (uint256));

        AuctionStruct memory auction = s_auctionsFromAuctionId[auctionId];

        if (auction.higherBidder != address(0)) {
            closeAuction(auctionId);
        } else {
            restartAuction(auctionId);
        }
    }

    // Function to initialize an auction
    function openNewAuction(
        uint256 _tokenId,
        AuctionType _auctionType
    ) public onlyOwner {
        if (address(yoyoNftContract) == address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        if (yoyoNftContract.getIfTokenIdIsMintable(_tokenId) == false) {
            revert YoyoAuction__InvalidTokenId();
        }

        AuctionStruct memory auction = s_auctionsFromAuctionId[
            s_auctionCounter
        ];
        if (auction.state == AuctionState.OPEN) {
            revert YoyoAuction__AuctionStillOpen();
        }

        uint256 newAuctionId = ++s_auctionCounter;
        uint256 endTime = block.timestamp +
            (s_auctionDurationInHours * 1 hours);

        AuctionStruct memory newAuction;

        if (_auctionType == AuctionType.ENGLISH) {
            newAuction = openNewEnglishAuction(_tokenId, newAuctionId, endTime);
        } else if (_auctionType == AuctionType.DUTCH) {
            newAuction = openNewDutchAuction(_tokenId, newAuctionId, endTime);
        } else {
            revert YoyoAuction__InvalidAuctionType();
        }

        s_auctionsFromAuctionId[newAuctionId] = newAuction;

        emit YoyoAuction__AuctionOpened(
            newAuctionId,
            _tokenId,
            newAuction.auctionType,
            newAuction.startPrice,
            newAuction.startTime,
            newAuction.endTime,
            newAuction.minimumBidChangeAmount
        );
    }

    function openNewEnglishAuction(
        uint256 _tokenId,
        uint256 _auctionId,
        uint256 _endTime
    ) private view returns (AuctionStruct memory) {
        uint256 startPrice = yoyoNftContract.getBasicMintPrice();

        AuctionStruct memory newAuction = AuctionStruct({
            auctionId: _auctionId,
            tokenId: _tokenId,
            nftOwner: address(0),
            state: AuctionState.OPEN,
            auctionType: AuctionType.ENGLISH,
            startPrice: startPrice,
            startTime: block.timestamp,
            endTime: _endTime,
            higherBidder: address(0),
            higherBid: startPrice,
            minimumBidChangeAmount: s_minimumBidChangeAmount
        });

        return newAuction;
    }

    function openNewDutchAuction(
        uint256 _tokenId,
        uint256 _auctionId,
        uint256 _endTime
    ) private view returns (AuctionStruct memory) {
        uint256 startPrice = yoyoNftContract.getBasicMintPrice() *
            s_dutchAuctionStartPriceMultiplier;
        uint256 dropAmount = YoyoDutchAuctionLibrary
            .dropAmountFromPricesAndIntervalsCalculator(
                yoyoNftContract.getBasicMintPrice(),
                startPrice,
                s_dutchAuctionDropNumberOfIntervals
            );

        AuctionStruct memory newAuction = AuctionStruct({
            auctionId: _auctionId,
            tokenId: _tokenId,
            nftOwner: address(0),
            state: AuctionState.OPEN,
            auctionType: AuctionType.DUTCH,
            startPrice: startPrice,
            startTime: block.timestamp,
            endTime: _endTime,
            higherBidder: address(0),
            higherBid: startPrice,
            minimumBidChangeAmount: dropAmount
        });

        return newAuction;
    }

    // Function to place a bid on an auction
    function placeBidOnAuction(
        uint256 _auctionId
    ) external payable nonReentrant {
        AuctionStruct memory auction = s_auctionsFromAuctionId[_auctionId];
        if (auction.startTime == 0) {
            revert YoyoAuction__AuctionDoesNotExist();
        }
        if (auction.state != AuctionState.OPEN) {
            revert YoyoAuction__AuctionNotOpen();
        }
        if (auction.auctionType == AuctionType.DUTCH) {
            placeBidOnDutchAuction(_auctionId, msg.sender);
        } else if (auction.auctionType == AuctionType.ENGLISH) {
            placeBidOnEnglishAuction(_auctionId, msg.sender);
        }

        // Emit an event for the new bid
        emit YoyoAuction__BidPlaced(
            _auctionId,
            msg.sender,
            msg.value,
            auction.auctionType
        );
    }

    function placeBidOnDutchAuction(
        uint256 _auctionId,
        address _sender
    ) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        uint256 currentPrice = getCurrentAuctionPrice();

        if (msg.value < currentPrice) {
            revert YoyoAuction__BidTooLow();
        }
        // Update the auction with the new bid
        auction.higherBidder = _sender;
        auction.higherBid = msg.value;

        closeAuction(auction.auctionId);
    }

    function placeBidOnEnglishAuction(
        uint256 _auctionId,
        address _sender
    ) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        if (msg.value < auction.higherBid + auction.minimumBidChangeAmount) {
            revert YoyoAuction__BidTooLow();
        }
        //refund previous bidder
        if (auction.higherBidder != address(0)) {
            refundPreviousBidder(
                auction.higherBid,
                auction.higherBidder,
                auction.auctionId
            );
        }

        // Update the auction with the new bid
        auction.higherBidder = _sender;
        auction.higherBid = msg.value;
    }

    function refundPreviousBidder(
        uint256 _amount,
        address _previousBidder,
        uint256 _auctionId
    ) private {
        if (_previousBidder != address(0) && _amount > 0) {
            (bool success, ) = _previousBidder.call{value: _amount}("");
            if (!success) {
                revert YoyoAuction__PreviousBidderRefundFailed();
            } else
                emit YoyoAuction__BidderRefunded(
                    _previousBidder,
                    _amount,
                    _auctionId
                );
        }
    }

    //Function to handle auction after the ending time
    function closeAuction(uint256 _auctionId) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];
        if (auction.state == AuctionState.OPEN) {
            auction.state = AuctionState.CLOSED;
        }
        if (auction.auctionType == AuctionType.DUTCH) {
            auction.endTime = block.timestamp; // Set end time to current time for Dutch auction
        }
        emit YoyoAuction__AuctionClosed(
            auction.auctionId,
            auction.tokenId,
            auction.startPrice,
            auction.startTime,
            auction.endTime,
            auction.higherBidder,
            auction.higherBid
        );

        try
            yoyoNftContract.mintNft{value: auction.higherBid}(
                auction.higherBidder,
                auction.tokenId
            )
        {
            auction.state = AuctionState.FINALIZED;
            auction.nftOwner = auction.higherBidder;

            emit YoyoAuction__AuctionFinalized(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder
            );
        } catch Error(string memory reason) {
            emit YoyoAuction__MintFailedLog(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder,
                reason
            );
        } catch {
            emit YoyoAuction__MintFailedLog(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder,
                "unknown error"
            );
        }
    }

    function restartAuction(uint256 _auctionId) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        uint256 startPrice;
        if (auction.auctionType == AuctionType.ENGLISH) {
            startPrice = yoyoNftContract.getBasicMintPrice();
        } else if (auction.auctionType == AuctionType.DUTCH) {
            startPrice = YoyoDutchAuctionLibrary
                .startPriceFromReserveAndMultiplierCalculator(
                    yoyoNftContract.getBasicMintPrice(),
                    s_dutchAuctionStartPriceMultiplier,
                    1 // Using 1 interval for restart
                );
        }
        uint256 endTime = block.timestamp +
            (s_auctionDurationInHours * 1 hours);

        auction.startTime = block.timestamp;
        auction.endTime = endTime;
        auction.startPrice = startPrice;
        auction.higherBid = startPrice;
        auction.minimumBidChangeAmount = s_minimumBidChangeAmount;

        emit YoyoAuction__AuctionRestarted(
            auction.auctionId,
            auction.tokenId,
            auction.startTime,
            auction.startPrice,
            auction.endTime,
            auction.minimumBidChangeAmount
        );
    }

    function manualMintForWinner(uint256 _auctionId) public onlyOwner {
        if (address(yoyoNftContract) != address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        if (auction.nftOwner != address(0)) {
            revert YoyoAuction__NoTokenToMint();
        }
        if (auction.state != AuctionState.CLOSED) {
            revert YoyoAuction__NoTokenToMint();
        }

        try
            yoyoNftContract.mintNft{value: auction.higherBid}(
                auction.higherBidder,
                auction.tokenId
            )
        {
            auction.state = AuctionState.FINALIZED;
            auction.nftOwner = auction.higherBidder;

            emit YoyoAuction__AuctionFinalized(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder
            );
        } catch Error(string memory reason) {
            emit YoyoAuction__MintFailedLog(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder,
                reason
            );
        } catch {
            emit YoyoAuction__MintFailedLog(
                auction.auctionId,
                auction.tokenId,
                auction.higherBidder,
                "unknown error"
            );
        }
    }

    // Functions to change auction parameters
    function changeMintPrice(uint256 _newPrice) public onlyOwner {
        if (address(yoyoNftContract) == address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        if (_newPrice == 0) {
            revert YoyoAuction__InvalidValue();
        }
        AuctionStruct memory currentAuction = s_auctionsFromAuctionId[
            s_auctionCounter
        ];
        if (
            currentAuction.state == AuctionState.OPEN &&
            currentAuction.higherBid < _newPrice
        ) {
            revert YoyoAuction__CannotChangeMintPriceDuringOpenAuction();
        }
        yoyoNftContract.setBasicMintPrice(_newPrice);
        s_minimumBidChangeAmount = _newPrice / 40; // 2,5% of the basic mint price
    }

    //Getter Functions
    function getContractOwner() external view returns (address) {
        return i_owner;
    }

    function getNftContract() external view returns (address) {
        return address(yoyoNftContract);
    }

    function getAuctionCounter() external view returns (uint256) {
        return s_auctionCounter;
    }

    function getAuctionDurationInHours() external view returns (uint256) {
        return s_auctionDurationInHours;
    }

    function getMinimumBidChangeAmount() external view returns (uint256) {
        return s_minimumBidChangeAmount;
    }

    function getDutchAuctionStartPriceMultiplier()
        external
        view
        returns (uint256)
    {
        return s_dutchAuctionStartPriceMultiplier;
    }

    function getAuctionFromAuctionId(
        uint256 _auctionId
    ) public view returns (AuctionStruct memory) {
        return s_auctionsFromAuctionId[_auctionId];
    }

    function getCurrentAuction() public view returns (AuctionStruct memory) {
        return s_auctionsFromAuctionId[s_auctionCounter];
    }

    function getCurrentAuctionPrice() public view returns (uint256) {
        AuctionStruct memory auction = s_auctionsFromAuctionId[
            s_auctionCounter
        ];
        if (auction.state != AuctionState.OPEN) {
            revert YoyoAuction__AuctionNotOpen();
        }
        if (auction.auctionType == AuctionType.ENGLISH) {
            return auction.higherBid + auction.minimumBidChangeAmount;
        }
        if (auction.auctionType == AuctionType.DUTCH) {
            uint256 dropAmount = YoyoDutchAuctionLibrary
                .dropAmountFromPricesAndIntervalsCalculator(
                    yoyoNftContract.getBasicMintPrice(),
                    auction.startPrice,
                    s_dutchAuctionDropNumberOfIntervals
                );
            return
                YoyoDutchAuctionLibrary.currentPriceFromTimeRangeCalculator(
                    auction.startPrice,
                    yoyoNftContract.getBasicMintPrice(),
                    dropAmount,
                    auction.startTime,
                    auction.endTime,
                    s_dutchAuctionDropNumberOfIntervals
                );
        }
        return auction.higherBid;
    }
}
