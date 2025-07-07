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

contract YoyoNft is ERC721 {
    /* Errors */
    error YoyoNft__NotOwner();
    error YoyoNft__InvalidAddress();
    error YoyoNft__ValueCantBeZero();
    error YoyoNft__TokenIdDoesNotExist();
    error YoyoNft__TokenIdAlreadyExists();
    error YoyoNft__NftAlreadyMinted();
    error YoyoNft__NftMaxSupplyReached();
    error YoyoNft__NotEnoughEtherSent();
    error YoyoNft__ContractBalanceIsZero();
    error YoyoNft__WithdrawFailed();
    error YoyoNft__ThisContractDoesntAcceptDeposit();
    error YoyoNft__CallValidFunctionToInteractWithContract();

    /* Type declarations */

    /* State variables */
    uint256 private s_tokenCounter;
    uint256 public constant MAX_NFT_SUPPLY = 20;
    uint256 private s_mintPrice = 0.01 ether;
    string private s_baseURI;
    address private immutable i_owner;

    mapping(uint256 => string) private s_tokenIdToURI;

    /* Events */
    event YoyoNft__WithdrawCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__DepositCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__MintPriceUpdated(uint256 newPrice, uint256 timestamp);
    event YoyoNft__NftMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string tokenURI,
        uint256 timestamp
    );

    /* Modifiers */
    modifier yoyoOnlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoNft__NotOwner();
        }
        _;
    }

    /* Functions */
    constructor(string memory baseURI) ERC721("Yoyo Collection", "YOYO") {
        i_owner = msg.sender;
        s_baseURI = baseURI;
        s_tokenCounter = 0;
    }

    receive() external payable {
        revert YoyoNft__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoNft__CallValidFunctionToInteractWithContract();
    }

    function withdraw() public yoyoOnlyOwner {
        if (address(this).balance == 0) {
            revert YoyoNft__ContractBalanceIsZero();
        }
        uint256 contractBalance = address(this).balance;
        bool success = payable(i_owner).send(contractBalance);
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

    function setMintPrice(uint256 _price) public yoyoOnlyOwner {
        if (_price == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        s_mintPrice = _price;

        emit YoyoNft__MintPriceUpdated(_price, block.timestamp);
    }

    function mintNft(uint256 tokenId) public payable {
        if (s_tokenCounter >= MAX_NFT_SUPPLY) {
            revert YoyoNft__NftMaxSupplyReached();
        }
        if (tokenId < 0 || tokenId > MAX_NFT_SUPPLY) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        if (msg.value < s_mintPrice) {
            revert YoyoNft__NotEnoughEtherSent();
        }
        _safeMint(msg.sender, tokenId);
        string memory tokenURIComplete = string(
            abi.encodePacked(s_baseURI, "/", Strings.toString(tokenId), ".json")
        );
        s_tokenIdToURI[tokenId] = tokenURIComplete;
        s_tokenCounter++;
    }

    function transferNft(address to, uint256 tokenId) public {
        if (to == address(0)) {
            revert YoyoNft__InvalidAddress();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert YoyoNft__NotOwner();
        }
        _safeTransfer(msg.sender, to, tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenId > MAX_NFT_SUPPLY || tokenId < 0) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        return s_tokenIdToURI[tokenId];
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

    function getMintPrice() public view returns (uint256) {
        return s_mintPrice;
    }
}
