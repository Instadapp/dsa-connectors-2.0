//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogDeposit(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogDepositWithoutCollateral(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogWithdraw(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogBorrow(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogRepay(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event LogRepayOnBehalfOf(
        address indexed token,
        address indexed vToken,
        uint256 tokenAmt,
        address onBehalfOf,
        uint256 getId,
        uint256 setId
    );
    event LogEnableCollateral(address[] vTokens);
    event LogDisableCollateral(address[] vTokens);
}
