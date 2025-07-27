// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {YoyoAuction} from "../../src/YoyoAuction.sol";
import {YoyoNft, ConstructorParams} from "../../src/YoyoNft.sol";

contract RevertOnReceiverMock {
    YoyoNft public nftContract;
    error RevertOnReceiverMock__ThisContractDoesntAcceptDeposit();

    constructor(ConstructorParams memory _params) {
        nftContract = new YoyoNft(_params);
    }

    /**
     * @dev This function pay auction contract to palce a bid and become the bidder who receive refund.
     */

    function payAuctionContract(
        address payable yoyoAuctionContract,
        uint256 auctionId
    ) public payable {
        YoyoAuction(yoyoAuctionContract).placeBidOnAuction{value: msg.value}(
            auctionId
        );
    }

    /**
     * @dev This function call withdraw and make it fail due to revert on receive function.
     */
    function callWithdrawFromNftContract(
        address payable yoyoNftContract
    ) public {
        YoyoNft(yoyoNftContract).withdraw();
    }

    function getNftContract() public view returns (YoyoNft) {
        return nftContract;
    }

    /**
     * @dev This function will always revert when receiving Ether.
     */

    receive() external payable {
        revert RevertOnReceiverMock__ThisContractDoesntAcceptDeposit();
    }

    /**
     * @dev Fallback function to handle calls to non-existent functions.
     */
    // fallback() external payable {
    //     revert RevertOnReceiverMock__ThisContractDoesntAcceptDeposit();
    // }
}
