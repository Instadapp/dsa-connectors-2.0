//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogFluidDexDeposit(
        address dex,
        address token0,
        address token1,
        uint256 token0Amt,
        uint256 token1Amt,
        uint256 minSharesAmt,
        bool estimate
    );
}
