// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IYoyoNft {
    // External functions
    function mintNft(address _to, uint256 _tokenId) external payable;

    function transferNft(address to, uint256 tokenId) external;

    function withdraw() external;

    function deposit() external payable;

    function setBasicMintPrice(uint256 _newBasicPrice) external;

    // View functions
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function getBaseURI() external view returns (string memory);

    function getTotalMinted() external view returns (uint256);

    function getOwnerFromTokenId(
        uint256 tokenId
    ) external view returns (address);

    function getAccountBalance(
        address _account
    ) external view returns (uint256);

    function getContractOwner() external view returns (address);

    function getAuctionContract() external view returns (address);

    function getBasicMintPrice() external view returns (uint256);

    function getIfTokenIdIsMintable(
        uint256 _tokenId
    ) external view returns (bool);
}
