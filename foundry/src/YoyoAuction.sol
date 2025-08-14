// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IYoyoNft } from './IYoyoNft.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import { AutomationCompatibleInterface } from '@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol';
import { YoyoDutchAuctionLibrary } from './YoyoDutchAuctionLibrary.sol';

/**
 * @title Nft Auction System
 * @author Elia Bordoni
 * @notice This contract manages english and dutch auction for Nft collection
 * @dev Implements automated auction lifecycle with reentrancy protection and Chainlink upkeep integration
 */

contract YoyoAuction is ReentrancyGuard, AutomationCompatibleInterface {
    /**
     * @dev Interface that allows contract to acces the NFT contract
     */
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

    /** 
     @dev notStarted: prevents the default value from being set to `open`.
     @dev open: auction is active and bids can be placed.
     @dev closed: auction has ended, no more bids can be placed, but the winner has not yet received the reward.
     @dev finalized: after the auction is closed and the NFT is minted and delivered to the winner, the auction is considered finalized.
     */
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

    /**
     * @dev Core data structure that holds all information about a single auction
     * @param auctionId Unique identifier for the auction
     * @param tokenId ID of the NFT being auctioned
     * @param nftOwner Address that will receive the NFT (set after finalization)
     * @param state Current state of the auction (NOT_STARTED, OPEN, CLOSED, FINALIZED)
     * @param auctionType Type of auction (ENGLISH or DUTCH)
     * @param startPrice Initial price when the auction begins
     * @param startTime Timestamp when the auction started
     * @param endTime Timestamp when the auction is scheduled to end
     * @param higherBidder Address of the current highest bidder
     * @param higherBid Amount of the current highest bid
     * @param minimumBidChangeAmount Minimum increment required for new bids (English) or drop amount (Dutch)
     */
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
    /**
     * @dev Contract owner address, set at deployment and immutable
     */
    address private immutable i_owner;
    
    /**
     * @dev Minimum amount required to increase a bid in English auctions
     * @dev Set to 2.5% of the basic mint price when NFT contract is initialized
     */
    uint256 private s_minimumBidChangeAmount;
    
    /**
     * @dev Duration of each auction in seconds (default: 24 hours)
     */
    uint256 private s_auctionDurationInHours = 24 hours;
    
    /**
     * @dev Counter that tracks the total number of auctions created
     * @dev Also serves as the ID for the current/latest auction
     */
    uint256 private s_auctionCounter;
    
    /**
     * @dev Number of price drop intervals for Dutch auctions (default: 48)
     * @dev Price drops occur at regular intervals throughout the auction duration
     */
    uint256 private s_dutchAuctionDropNumberOfIntervals = 48;
    
    /**
     * @dev Multiplier used to calculate Dutch auction starting price
     * @dev Start price = basic mint price * multiplier (default: 13x)
     */
    uint256 private s_dutchAuctionStartPriceMultiplier = 13;

    /** 
    @dev Mapping used to retrieve any necessary information about an auction starting from its auctionId.
    */
    mapping(uint256 => AuctionStruct) internal s_auctionsFromAuctionId;

    /* Events */
    event YoyoAuction__BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        AuctionType auctionType
    );
    event YoyoAuction__BidderRefunded(address prevBidderAddress, uint256 bidAmount, uint256 indexed auctionId);
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
    event YoyoAuction__AuctionFinalized(uint256 indexed auctionId, uint256 indexed tokenId, address indexed nftOwner);
    event YoyoAuction__MintFailedLog(uint256 indexed auctionId, uint256 tokenId, address bidder, string reason);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoAuction__NotOwner();
        }
        _;
    }

    /* Constructor */
    /**
     * @dev Contract constructor that sets the deployer as the owner
     * @dev Initializes auction counter to 0
     * @dev The NFT contract address must be set separately after deployment
     */
    constructor() {
        i_owner = msg.sender;
        s_auctionCounter = 0;
    }

    /*Functions */
    /**
     * @notice Sets the address of the NFT collection smart contract to be managed by the auction.
     * @notice This function is designed to be called only once. It can be called only from the owner.
     * @notice Since the two contracts (auction and NFT collection) are deployed together,
     * @dev the NFT collection address cannot be set in the constructor and must be set immediately after deployment.
     * @param _yoyoNftAddress the address of the nft collection smart contract
     */
    function setNftContract(address _yoyoNftAddress) external onlyOwner {
        if (yoyoNftContract != IYoyoNft(address(0))) {
            revert YoyoAuction__NftContractAlreadySet();
        }
        yoyoNftContract = IYoyoNft(_yoyoNftAddress);
        s_minimumBidChangeAmount = yoyoNftContract.getBasicMintPrice() / 40; // 2,5% of the basic mint price
    }

    /**
     * @dev Receive function that rejects all direct ETH transfers
     * @dev Forces users to use proper auction functions to interact with the contract
     */
    receive() external payable {
        revert YoyoAuction__ThisContractDoesntAcceptDeposit();
    }

    /**
     * @dev Fallback function that rejects all calls to non-existent functions
     * @dev Provides clear error message directing users to use valid functions
     */
    fallback() external payable {
        revert YoyoAuction__CallValidFunctionToInteractWithContract();
    }

    /* Functions */
    /**
     * @notice Called by Chainlink Keepers to check if upkeep is needed.
     * @notice Retrieves the latest auction using s_auctionCounter.
     * @notice Checks if the auction is currently open and if its end time has passed.
     * @notice upkeepNeeded is true only if the auction has ended but is still marked as open.
     * @dev performData encodes the auctionId to be used by performUpkeep for execution.
     * @return upkeepNeeded Boolean indicating whether upkeep should be performed.
     * @return performData Encoded data to be passed to performUpkeep, containing the auctionId.
     */
    function checkUpkeep(
        bytes calldata /*checkData*/
    ) public view override returns (bool upkeepNeeded, bytes memory performData) {
        AuctionStruct memory auction = s_auctionsFromAuctionId[s_auctionCounter];
        bool auctionOpen = auction.state == AuctionState.OPEN;
        bool auctionEnded = block.timestamp >= auction.endTime;
        uint256 auctionId = auction.auctionId;

        upkeepNeeded = (auctionEnded && auctionOpen);
        performData = abi.encode(auctionId);
        return (upkeepNeeded, performData);
    }

    /**
     * @notice Executes the Chainlink Keepers upkeep if conditions are met.
     * @notice  checks if the auction has a higher bidder.If there is a new
     * @notice higher bidder, it means a bid has been placed and therefore
     * @notice the auction will be closed at the deadline. If instead there
     * @notice is no higher bidder, the auction will be restarted.
     * @dev Decodes the auctionId from performData.
     * @dev Reverts if `checkUpkeep` returns `upkeepNeeded = false`.
     * @param performData Encoded data containing the auctionId to process.
     */
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

    /**
     * @notice Opens a new auction for a given NFT token, with a specified auction type.
     * @dev Only the contract owner can call this function.
     * @dev Validates the NFT contract, token ID, and ensures no overlapping auctions.
     * @dev Once the checks are completed, it will call the initialization function specific
     * to the chosen auction type.
     * @dev After the execution of the type-specific function is finished, it will emit the
     * auction opened event.
     * @param _tokenId The ID of the NFT to be auctioned.
     * @param _auctionType The type of auction (ENGLISH or DUTCH).
     */
    function openNewAuction(uint256 _tokenId, AuctionType _auctionType) public onlyOwner {
        if (address(yoyoNftContract) == address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        if (yoyoNftContract.getIfTokenIdIsMintable(_tokenId) == false) {
            revert YoyoAuction__InvalidTokenId();
        }

        AuctionStruct memory auction = s_auctionsFromAuctionId[s_auctionCounter];
        if (auction.state == AuctionState.OPEN) {
            revert YoyoAuction__AuctionStillOpen();
        }

        uint256 newAuctionId = ++s_auctionCounter;
        uint256 endTime = block.timestamp + (s_auctionDurationInHours * 1 hours);

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

    /**
     * @dev Creates a new English auction structure with appropriate parameters
     * @dev English auctions start at the basic mint price and increase with each bid
     * @param _tokenId ID of the NFT to be auctioned
     * @param _auctionId Unique identifier for this auction
     * @param _endTime Timestamp when the auction will end
     * @return AuctionStruct memory structure containing all auction parameters
     */
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

    /**
     * @dev Creates a new Dutch auction structure with appropriate parameters
     * @dev Dutch auctions start at a high price (mint price * multiplier) and decrease over time
     * @param _tokenId ID of the NFT to be auctioned
     * @param _auctionId Unique identifier for this auction
     * @param _endTime Timestamp when the auction will end
     * @return AuctionStruct memory structure containing all auction parameters
     */
    function openNewDutchAuction(
        uint256 _tokenId,
        uint256 _auctionId,
        uint256 _endTime
    ) private view returns (AuctionStruct memory) {
        uint256 startPrice = yoyoNftContract.getBasicMintPrice() * s_dutchAuctionStartPriceMultiplier;
        uint256 dropAmount = YoyoDutchAuctionLibrary.dropAmountFromPricesAndIntervalsCalculator(
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

        /**
     * @notice Allows users to place bids on active auctions
     * @dev Uses reentrancy guard to prevent reentrancy attacks
     * @dev Validates auction existence and state before processing bid
     * @dev Delegates to specific bid processing functions based on auction type
     * @param _auctionId ID of the auction to bid on
     */
    function placeBidOnAuction(uint256 _auctionId) external payable nonReentrant {
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
        emit YoyoAuction__BidPlaced(_auctionId, msg.sender, msg.value, auction.auctionType);
    }

    /**
     * @notice Processes a bid on a Dutch auction where any bid at or above current price wins immediately
     * @dev In Dutch auctions, any bid at or above current price wins immediately
     * @dev Closes the auction immediately upon successful bid
     * @param _auctionId ID of the Dutch auction
     * @param _sender Address of the bidder
     */
    function placeBidOnDutchAuction(uint256 _auctionId, address _sender) private {
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

    /**
     * @notice Processes a bid on an English auction with minimum increment validation and previous bidder refund
     * @dev Validates that bid meets minimum increment requirements
     * @dev Refunds the previous highest bidder before accepting new bid
     * @param _auctionId ID of the English auction
     * @param _sender Address of the bidder
     */
    function placeBidOnEnglishAuction(uint256 _auctionId, address _sender) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        if (msg.value < auction.higherBid + auction.minimumBidChangeAmount) {
            revert YoyoAuction__BidTooLow();
        }
        //refund previous bidder
        if (auction.higherBidder != address(0)) {
            refundPreviousBidder(auction.higherBid, auction.higherBidder, auction.auctionId);
        }

        // Update the auction with the new bid
        auction.higherBidder = _sender;
        auction.higherBid = msg.value;
    }

    /**
     * @notice Safely refunds the previous highest bidder when a new higher bid is placed in English auctions
     * @dev Uses low-level call to send ETH and handles failure appropriately
     * @param _amount Amount to refund
     * @param _previousBidder Address to receive the refund
     * @param _auctionId Auction ID for event logging
     */
    function refundPreviousBidder(uint256 _amount, address _previousBidder, uint256 _auctionId) private {
        if (_previousBidder != address(0) && _amount > 0) {
            (bool success, ) = _previousBidder.call{ value: _amount }('');
            if (!success) {
                revert YoyoAuction__PreviousBidderRefundFailed();
            } else emit YoyoAuction__BidderRefunded(_previousBidder, _amount, _auctionId);
        }
    }

    /**
     * @notice Closes an auction and attempts to automatically mint the NFT to the winner
     * @dev Called automatically by Chainlink Keepers when an auction ends with new bids
     * @dev Changes auction state to CLOSED and attempts NFT minting
     * @dev If minting succeeds, finalizes the auction; if it fails, logs the error
     * @param _auctionId ID of the auction to close
     */
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

        try yoyoNftContract.mintNft{ value: auction.higherBid }(auction.higherBidder, auction.tokenId) {
            auction.state = AuctionState.FINALIZED;
            auction.nftOwner = auction.higherBidder;

            emit YoyoAuction__AuctionFinalized(auction.auctionId, auction.tokenId, auction.higherBidder);
        } catch Error(string memory reason) {
            emit YoyoAuction__MintFailedLog(auction.auctionId, auction.tokenId, auction.higherBidder, reason);
        } catch {
            emit YoyoAuction__MintFailedLog(auction.auctionId, auction.tokenId, auction.higherBidder, 'unknown error');
        }
    }

    /**
     * @notice Automatically restarts an auction that ended without receiving any bids
     * @dev Resets auction timing and pricing parameters for a new auction cycle
     * @dev Called automatically by Chainlink Keepers when an auction ends without bids
     * @param _auctionId ID of the auction to restart
     */
    function restartAuction(uint256 _auctionId) private {
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        uint256 startPrice;
        if (auction.auctionType == AuctionType.ENGLISH) {
            startPrice = yoyoNftContract.getBasicMintPrice();
        } else if (auction.auctionType == AuctionType.DUTCH) {
            startPrice = YoyoDutchAuctionLibrary.startPriceFromReserveAndMultiplierCalculator(
                yoyoNftContract.getBasicMintPrice(),
                s_dutchAuctionStartPriceMultiplier,
                1 // Using 1 interval for restart
            );
        }
        uint256 endTime = block.timestamp + (s_auctionDurationInHours * 1 hours);

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

    /**
     * @notice Manual function to mint NFT for auction winner when automatic minting fails
     * @dev Can only be called by the contract owner
     * @dev Used as a fallback when the automatic minting in closeAuction() fails
     * @dev Validates that the auction is in CLOSED state and has a winner
     * @dev Minting process mirrors closeAuction() behavior:
     *      - Forwards the winner's bid amount as value to mintNft()
     *      - Uses try-catch to handle potential failures gracefully
     *      - On success: sets state to FINALIZED and updates nftOwner
     *      - On failure: emits MintFailedLog with error details for debugging
     * @dev Critical for maintaining auction integrity when automatic processes fail
     * @dev Should be called promptly after identifying failed automatic minting
     * @param _auctionId ID of the auction to manually finalize
     */
    function manualMintForWinner(uint256 _auctionId) public onlyOwner {
        if (address(yoyoNftContract) == address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        AuctionStruct storage auction = s_auctionsFromAuctionId[_auctionId];

        if (auction.nftOwner != address(0) || auction.state != AuctionState.CLOSED) {
            revert YoyoAuction__NoTokenToMint();
        }

        try yoyoNftContract.mintNft{ value: auction.higherBid }(auction.higherBidder, auction.tokenId) {
            auction.state = AuctionState.FINALIZED;
            auction.nftOwner = auction.higherBidder;

            emit YoyoAuction__AuctionFinalized(auction.auctionId, auction.tokenId, auction.higherBidder);
        } catch Error(string memory reason) {
            emit YoyoAuction__MintFailedLog(auction.auctionId, auction.tokenId, auction.higherBidder, reason);
        } catch {
            emit YoyoAuction__MintFailedLog(auction.auctionId, auction.tokenId, auction.higherBidder, 'unknown error');
        }
    }

    /**
     * @notice Allows the owner to change the basic mint price for future auctions
     * @dev Validates that the new price doesn't conflict with ongoing auctions
     * @dev Updates the minimum bid change amount proportionally (2.5% of new price)
     * @dev Cannot be called if current auction has bids below the new price
     * @dev The logic is designed to prevent the winner's final bid from being lower than
     *      the basic mint price, which would make minting impossible
     * @param _newPrice New basic mint price in wei
     */
    function changeMintPrice(uint256 _newPrice) public onlyOwner {
        if (address(yoyoNftContract) == address(0)) {
            revert YoyoAuction__NftContractNotSet();
        }
        if (_newPrice == 0) {
            revert YoyoAuction__InvalidValue();
        }
        AuctionStruct memory currentAuction = s_auctionsFromAuctionId[s_auctionCounter];
        if (currentAuction.state == AuctionState.OPEN && currentAuction.higherBid < _newPrice) {
            revert YoyoAuction__CannotChangeMintPriceDuringOpenAuction();
        }
        yoyoNftContract.setBasicMintPrice(_newPrice);
        s_minimumBidChangeAmount = _newPrice / 40; // 2,5% of the basic mint price
    }

    //Getter Functions
    function getContractOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Returns the address of the NFT contract managed by this auction
     * @dev This address must be set before auctions can be created.
     * @dev Used throughout the contract to call NFT-specific functions through the IYoyoNft interface.
     * @return address Address of the NFT collection contract
     */
    function getNftContract() external view returns (address) {
        return address(yoyoNftContract);
    }

    /**
     * @notice Returns the total number of auctions created so far
     * @dev This value also represents the ID of the latest auction.
     * @dev Used as a reference key for `s_auctionsFromAuctionId` mapping and in functions like `getCurrentAuction` and `changeMintPrice`.
     * @return uint256 Current auction counter
     */
    function getAuctionCounter() external view returns (uint256) {
        return s_auctionCounter;
    }

    /**
     * @notice Returns the duration of each auction in hours
     * @dev Default is 24 hours unless modified.
     * @dev Used in auction creation functions (`openNewAuction`, `restartAuction`) to calculate `endTime`.
     * @return uint256 Auction duration in hours
     */
    function getAuctionDurationInHours() external view returns (uint256) {
        return s_auctionDurationInHours;
    }

    /**
     * @notice Returns the minimum amount required to outbid the current highest bid
     * @dev For English auctions, this is set to 2.5% of the basic mint price.
     * @dev Used in `placeBidOnEnglishAuction` to validate bid increments and in auction initialization.
     * @return uint256 Minimum bid increment in wei
     */
    function getMinimumBidChangeAmount() external view returns (uint256) {
        return s_minimumBidChangeAmount;
    }

    /**
     * @notice Returns the multiplier used to calculate Dutch auction starting price
     * @dev Starting price = basic mint price * multiplier.
     * @dev Used in `openNewDutchAuction` and `restartAuction` to determine starting price for Dutch auctions.
     * @return uint256 Dutch auction start price multiplier
     */
    function getDutchAuctionStartPriceMultiplier() external view returns (uint256) {
        return s_dutchAuctionStartPriceMultiplier;
    }

    /**
     * @notice Returns all information about a specific auction by its ID
     * @dev Includes pricing, timing, current bids, and auction state.
     * @dev Used in multiple parts of the contract for bid validation, auction status checks, and Chainlink upkeep logic.
     * @param _auctionId ID of the auction to retrieve
     * @return AuctionStruct Full auction data structure
     */
    function getAuctionFromAuctionId(uint256 _auctionId) public view returns (AuctionStruct memory) {
        return s_auctionsFromAuctionId[_auctionId];
    }

    /**
     * @notice Returns the latest auction created
     * @dev Fetches auction data using the current auction counter.
     * @dev Used in functions like `getCurrentAuctionPrice` and `changeMintPrice` to operate on the most recent auction.
     * @return AuctionStruct Full data of the latest auction
     */
    function getCurrentAuction() public view returns (AuctionStruct memory) {
        return s_auctionsFromAuctionId[s_auctionCounter];
    }

    /**
     * @notice Returns the current price of the ongoing auction
     * @dev For English auctions: highest bid + minimum increment.
     * @dev For Dutch auctions: calculated based on elapsed time and price drop intervals.
     * @dev Used in `placeBidOnDutchAuction` to validate the bid amount and ensure the winner pays the current fair price.
     * @dev Reverts if no auction is currently open.
     * @return uint256 Current auction price in wei
     */
    function getCurrentAuctionPrice() public view returns (uint256) {
        AuctionStruct memory auction = s_auctionsFromAuctionId[s_auctionCounter];
        uint256 currentPrice;
        if (auction.state != AuctionState.OPEN) {
            revert YoyoAuction__AuctionNotOpen();
        }
        if (auction.auctionType == AuctionType.ENGLISH) {
            currentPrice = auction.higherBid + auction.minimumBidChangeAmount;
        }
        if (auction.auctionType == AuctionType.DUTCH) {
            uint256 dropAmount = YoyoDutchAuctionLibrary.dropAmountFromPricesAndIntervalsCalculator(
                yoyoNftContract.getBasicMintPrice(),
                auction.startPrice,
                s_dutchAuctionDropNumberOfIntervals
            );
            currentPrice = YoyoDutchAuctionLibrary.currentPriceFromTimeRangeCalculator(
                auction.startPrice,
                yoyoNftContract.getBasicMintPrice(),
                dropAmount,
                auction.startTime,
                auction.endTime,
                s_dutchAuctionDropNumberOfIntervals
            );
        }
        return currentPrice;
    }
}
