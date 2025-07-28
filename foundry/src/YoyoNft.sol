// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title A Yoga NFT collection
 * @author Elia Bordoni
 * @notice
 * @dev
 */

/* Type declarations */
struct ConstructorParams {
    string baseURI;
    address auctionContract;
    uint256 basicMintPrice;
}

contract YoyoNft is ERC721 {
    /* Errors */
    error YoyoNft__NotOwner();
    error YoyoNft__InvalidAddress();
    error YoyoNft__ValueCantBeZero();
    error YoyoNft__TokenIdDoesNotExist();
    error YoyoNft__TokenIdAlreadyExists();
    error YoyoNft__NftAlreadyMinted();
    error YoyoNft__NftNotMinted();
    error YoyoNft__NftMaxSupplyReached();
    error YoyoNft__NotEnoughEtherSent();
    error YoyoNft__ContractBalanceIsZero();
    error YoyoNft__WithdrawFailed();
    error YoyoNft__ThisContractDoesntAcceptDeposit();
    error YoyoNft__CallValidFunctionToInteractWithContract();
    error YoyoNft__NotAuctionContract();

    /* State variables */
    uint256 private s_tokenCounter;
    uint256 public constant MAX_NFT_SUPPLY = 20;
    uint256 private s_basicMintPrice;
    string private s_baseURI;
    address private immutable i_owner;
    address private immutable i_auctionContract;

    /* Events */
    event YoyoNft__WithdrawCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__DepositCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__MintPriceUpdated(uint256 newBasicPrice, uint256 timestamp);
    event YoyoNft__NftMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string tokenURI,
        uint256 timestamp
    );
    event YoyoNft__NftTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    /* Modifiers */
    modifier yoyoOnlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoNft__NotOwner();
        }
        _;
    }

    modifier yoyoOnlyAuctionContract() {
        if (msg.sender != i_auctionContract) {
            revert YoyoNft__NotAuctionContract();
        }
        _;
    }

    /* Functions */
    constructor(
        ConstructorParams memory _params
    ) ERC721("Yoyo Collection", "YOYO") {
        if (bytes(_params.baseURI).length == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        if (_params.auctionContract == address(0)) {
            revert YoyoNft__InvalidAddress();
        }
        i_owner = msg.sender;
        s_baseURI = _params.baseURI;
        s_tokenCounter = 0;
        i_auctionContract = _params.auctionContract;
        s_basicMintPrice = _params.basicMintPrice;
    }

    receive() external payable {
        revert YoyoNft__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoNft__CallValidFunctionToInteractWithContract();
    }

    function withdraw() public yoyoOnlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert YoyoNft__ContractBalanceIsZero();
        }
        (bool success, ) = payable(i_owner).call{value: contractBalance}("");
        if (success) {
            emit YoyoNft__WithdrawCompleted(contractBalance, block.timestamp);
        } else {
            revert YoyoNft__WithdrawFailed();
        }
    }

    function deposit() public payable yoyoOnlyOwner {
        if (msg.value == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        emit YoyoNft__DepositCompleted(msg.value, block.timestamp);
    }

    function setBasicMintPrice(
        uint256 _newBasicPrice
    ) public yoyoOnlyAuctionContract {
        if (_newBasicPrice == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        s_basicMintPrice = _newBasicPrice;

        emit YoyoNft__MintPriceUpdated(_newBasicPrice, block.timestamp);
    }

    function mintNft(
        address _to,
        uint256 _tokenId
    ) external payable yoyoOnlyAuctionContract {
        if (s_tokenCounter == MAX_NFT_SUPPLY) {
            revert YoyoNft__NftMaxSupplyReached();
        }
        if (_ownerOf(_tokenId) != address(0)) {
            revert YoyoNft__NftAlreadyMinted();
        }
        if (_tokenId >= MAX_NFT_SUPPLY) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        if (msg.value < s_basicMintPrice) {
            revert YoyoNft__NotEnoughEtherSent();
        }
        if (_to == address(0)) {
            revert YoyoNft__InvalidAddress();
        }
        _safeMint(_to, _tokenId);
        string memory tokenURIComplete = tokenURI(_tokenId);
        s_tokenCounter++;

        emit YoyoNft__NftMinted(
            _to,
            _tokenId,
            tokenURIComplete,
            block.timestamp
        );
    }

    function transferNft(address to, uint256 tokenId) public {
        if (to == address(0)) {
            revert YoyoNft__InvalidAddress();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert YoyoNft__NotOwner();
        }
        _safeTransfer(msg.sender, to, tokenId);

        emit YoyoNft__NftTransferred(msg.sender, to, tokenId, block.timestamp);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (_tokenId >= MAX_NFT_SUPPLY) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        if (_ownerOf(_tokenId) == address(0)) {
            revert YoyoNft__NftNotMinted();
        }
        return
            string(
                abi.encodePacked(
                    s_baseURI,
                    "/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function getBaseURI() public view returns (string memory) {
        return s_baseURI;
    }

    function getTotalMinted() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getOwnerFromTokenId(
        uint256 tokenId
    ) public view returns (address) {
        return ownerOf(tokenId);
    }

    function getAccountBalance(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }

    function getAuctionContract() public view returns (address) {
        return i_auctionContract;
    }

    function getBasicMintPrice() public view returns (uint256) {
        return s_basicMintPrice;
    }

    function getIfTokenIdIsMintable(
        uint256 _tokenId
    ) public view returns (bool) {
        return _ownerOf(_tokenId) == address(0) && _tokenId < MAX_NFT_SUPPLY;
    }
}
