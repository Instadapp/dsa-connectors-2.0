//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogDeposit(
        uint256 daiAmount,
        uint256 usdsAmount,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        uint256 usdsAmount,
        uint256 daiAmount,
        uint256 getId,
        uint256 setId
    );
}
