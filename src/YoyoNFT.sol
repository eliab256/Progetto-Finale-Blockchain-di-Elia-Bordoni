// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title A Yoga NFT collection
 * @author Elia Bordoni
 * @notice
 * @dev
 */

contract YoyoNft is ERC721 {
    /* Errors */
    error YoyoNft__NotOwner();
    error YoyoNft__ValueCantBeZero();
    error YoyoNft__TokenIdDoesNotExist();
    error YoyoNft__ContractBalanceIsZero();
    error YoyoNft__WithdrawFailed();
    error YoyoNft__ThisContractDoesntAcceptDeposit();
    error YoyoNft__CallValidFunctionToInteractWithContract();

    /* Type declarations */

    /* State variables */
    string private s_baseURI;
    address public immutable i_owner;

    /* Events */

    event YoyoNft__WithdrawCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__DepositCompleted(uint256 amount, uint256 timestamp);

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
}
