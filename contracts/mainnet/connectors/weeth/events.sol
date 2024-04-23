//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Events {
    event LogDeposit(
        uint256 eETHAmount,
        uint256 weETHAmount,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        uint256 weETHAmount,
        uint256 eETHAmount,
        uint256 getId,
        uint256 setId
    );
}
