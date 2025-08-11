// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @title A Yoga NFT collection
 * @author Elia Bordoni
 * @notice This contract manages a limited collection of yoga-themed NFTs with auction integration
 * @dev Extends ERC721 with custom minting logic, auction contract integration, and owner-only functions
 * @dev The contract communicates with the YoyoAuction via a custom interface that only implements
 */

/**  Type declarations
 * @notice Parameters structure for contract initialization
 * @dev Used to avoid stack too deep errors in constructor
 * @param s_baseURI the base URI for Yoyo NFTs' metadata stored in IPFS, the format of the string should be ipfs://<CID>
 * @param i_auctionContract the address of auction contract that allows to mint new nfts
 * @param s_basicMintPrice It is the initial mint price, also used as the auction starting bid in the YoyoAuction contract.
 */
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
    event YoyoNft__NftMinted(address indexed owner, uint256 indexed tokenId, string tokenURI, uint256 timestamp);
    event YoyoNft__NftTransferred(address indexed from, address indexed to, uint256 indexed tokenId, uint256 timestamp);

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

    /**
     * @notice The ERC721 token is inizialized with the name "Yoyo Collection" and with the symbol "YOYO"
     * @dev The owner of the contract is set to be the sender of the deployment transaction
     */
    constructor(ConstructorParams memory _params) ERC721('Yoyo Collection', 'YOYO') {
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

    /* Functions */
    /**
     *@dev both receive and fallback functions refuse to accept eth and force users
     *@dev to use correct functions
     */
    receive() external payable {
        revert YoyoNft__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoNft__CallValidFunctionToInteractWithContract();
    }

    /**
     *@notice allows only the owner of the contract to widthraw founds from contract
     */
    function withdraw() public yoyoOnlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert YoyoNft__ContractBalanceIsZero();
        }
        (bool success, ) = payable(i_owner).call{ value: contractBalance }('');
        if (success) {
            emit YoyoNft__WithdrawCompleted(contractBalance, block.timestamp);
        } else {
            revert YoyoNft__WithdrawFailed();
        }
    }

    /**
     *@notice allows only the owner of the contract to deposit founds
     */
    function deposit() public payable yoyoOnlyOwner {
        if (msg.value == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        emit YoyoNft__DepositCompleted(msg.value, block.timestamp);
    }

    /**
     *@notice It allows setting the base minting price from the auction contract.
     *@dev This is because the logic of the auction contract must prevent the winner’s
     *@dev auction price from being in any way lower than the mint price, which would
     *@dev result in the minting process failing.
     *@param _newBasicPrice  is the new minting price
     */
    function setBasicMintPrice(uint256 _newBasicPrice) public yoyoOnlyAuctionContract {
        if (_newBasicPrice == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        s_basicMintPrice = _newBasicPrice;

        emit YoyoNft__MintPriceUpdated(_newBasicPrice, block.timestamp);
    }

    /**
     *@notice It allows auction contract to mint a new Nft to send to the auction winner
     *@dev Implementation of the safeMint function from ERC721 standard
     *@dev create the event whit all the information for the frontend like tokenURI and tokenId
     *@dev update tokenCounter to avoid max supply exceed
     *@param _to it is the recipient to whom the NFT will be sent immediately after it is minted.
     *@param _tokenId it is the unique Id of the token just minted
     */
    function mintNft(address _to, uint256 _tokenId) external payable yoyoOnlyAuctionContract {
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

        emit YoyoNft__NftMinted(_to, _tokenId, tokenURIComplete, block.timestamp);
    }

    /**
     *@notice Allows nft owner to transfer his nft to another user
     *@dev Implementation of the safeTransfer function from ERC721 standard
     *@dev create the event whit all the information for the frontend like tokenId and new owner
     *@param _to it is the recipient to whom the NFT will be sent.
     *@param _tokenId it is the unique Id of the token to send.
     */
    function transferNft(address _to, uint256 _tokenId) public {
        if (_to == address(0)) {
            revert YoyoNft__InvalidAddress();
        }
        if (ownerOf(_tokenId) != msg.sender) {
            revert YoyoNft__NotOwner();
        }
        _safeTransfer(msg.sender, _to, _tokenId);

        emit YoyoNft__NftTransferred(msg.sender, _to, _tokenId, block.timestamp);
    }

    /**
     *@notice Return the complete URI of a specific token from his Id
     *@param _tokenId it is the unique Id of the token.
     *@return tokenURI the complete unique URI related to the specific token
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId >= MAX_NFT_SUPPLY) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        if (_ownerOf(_tokenId) == address(0)) {
            revert YoyoNft__NftNotMinted();
        }
        return string(abi.encodePacked(s_baseURI, '/', Strings.toString(_tokenId), '.json'));
    }

    function getBaseURI() public view returns (string memory) {
        return s_baseURI;
    }

    function getTotalMinted() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getOwnerFromTokenId(uint256 tokenId) public view returns (address) {
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

    /**
     *@notice Checks whether a specific token ID can be minted or not.
     *@notice This means it verifies both whether it has already been minted
     *@notice and whether the ID is within the maximum supply.
     *@param _tokenId it is the unique Id of the token that user want to check.
     *@return boolean after check is complete, return fi is mintable (true) or not mintable (false)
     */
    function getIfTokenIdIsMintable(uint256 _tokenId) public view returns (bool) {
        return _ownerOf(_tokenId) == address(0) && _tokenId < MAX_NFT_SUPPLY;
    }
}
