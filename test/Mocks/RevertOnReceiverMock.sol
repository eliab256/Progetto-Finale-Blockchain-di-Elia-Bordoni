// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../src/YoyoAuction.sol";

contract RevertOnReceiverMock {
    error RevertOnReceiverMock__ThisContractDoesntAcceptDeposit();

    constructor() {}

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
