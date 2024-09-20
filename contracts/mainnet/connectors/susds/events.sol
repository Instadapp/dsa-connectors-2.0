//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogDeposit(
        uint256 usdsAmount,
        uint256 susdsAmount,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        uint256 susdsAmount,
        uint256 usdsAmount,
        uint256 getId,
        uint256 setId
    );
}
