//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Events {
    event LogDeposit(
        address market,
        uint256 minPtOut,
        address tokenIn,
        uint256 netTokenIn,
        uint256 setId
    );

    event LogWithdraw(
        address market,
        uint256 exactPtIn,
        address tokenOut,
        uint256 minTokenOut,
        uint256 setId
    );
}
