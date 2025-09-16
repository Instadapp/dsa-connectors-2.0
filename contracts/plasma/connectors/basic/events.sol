//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogDeposit(
        address indexed erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        address indexed erc20,
        uint256 tokenAmt,
        address indexed to,
        uint256 getId,
        uint256 setId
    );
    event LogDepositFrom(
        address indexed erc20,
        uint256 tokenAmt,
        address indexed from,
        uint256 getId,
        uint256 setId
    );
}
