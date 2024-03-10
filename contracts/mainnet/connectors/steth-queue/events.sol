//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogQueueSteth(
        uint256 stETHAmount,
        uint256 ethBorrowAmount,
        uint256 requestIdFrom,
        uint256 getId,
        uint256 setId
    );

    event LogClaimSteth(
        uint256 nftId,
        uint256 claimedAmount,
        uint256 repayAmount,
        uint256 getId,
        uint256 setIdClaimedAmt,
        uint256 setIdRepayAmt
    );
}
