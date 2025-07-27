// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YoyoNftMockFailingMint {
    bool public shouldFailMint = false;
    bool public shouldPanic = false;
    string public failureReason = "";
    uint256 public basicMintPrice = 0.01 ether;

    mapping(uint256 => bool) public tokenMintable;
    mapping(uint256 => address) public tokenOwner;

    constructor() {
        // Set some tokens as mintable
        for (uint i = 1; i <= 100; i++) {
            tokenMintable[i] = true;
        }
    }

    /**
     * @dev Configures the mock to fail with a specific error message
     */
    function setShouldFailMint(
        bool _shouldFail,
        string memory _reason
    ) external {
        shouldFailMint = _shouldFail;
        failureReason = _reason;
        shouldPanic = false; // Reset panic mode
    }

    /**
     * @dev Configures the mock to panic (without an error message)
     */
    function setShouldPanic(bool _shouldPanic) external {
        shouldPanic = _shouldPanic;
        shouldFailMint = false; // Reset failure mode
    }

    /**
     * @dev Mint function that can be configured to fail
     */
    function mintNft(address to, uint256 tokenId) external {
        if (shouldPanic) {
            // Triggers a panic (caught by generic catch)
            assembly {
                invalid() // Invalid opcode
            }
        }

        if (shouldFailMint) {
            // Revert with message (caught by catch Error)
            revert(failureReason);
        }

        // Normal mint
        require(tokenMintable[tokenId], "Token not mintable");
        tokenMintable[tokenId] = false;
        tokenOwner[tokenId] = to;
    }

    // Support functions for the YoyoAuction contract
    function getBasicMintPrice() external view returns (uint256) {
        return basicMintPrice;
    }

    function setBasicMintPrice(uint256 _price) external {
        basicMintPrice = _price;
    }

    function getIfTokenIdIsMintable(
        uint256 tokenId
    ) external view returns (bool) {
        return tokenMintable[tokenId];
    }

    // Helper for tests
    function resetToken(uint256 tokenId) external {
        tokenMintable[tokenId] = true;
        tokenOwner[tokenId] = address(0);
    }
}
