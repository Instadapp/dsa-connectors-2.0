//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogSwapExactIn(
        address assetIn,
        uint256 amountIn,
        uint256 getId,
        uint256 setId
    );
    event LogSwapExactOut(
        address assetOut,
        uint256 amountOut,
        uint256 getId,
        uint256 setId
    );
}
