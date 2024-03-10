//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFluidStETHQueue {
    function queue(
        uint256 ethBorrowAmount_,
        uint256 stETHAmount_,
        address borrowTo_,
        address claimTo_
    ) external returns (uint256 requestIdFrom_);

    function claim(
        address claimTo_,
        uint256 requestIdFrom_
    ) external returns (uint256 claimedAmount_, uint256 repayAmount_);
}
