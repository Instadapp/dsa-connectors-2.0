//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISparkPSM3 {
    function deposit(
        address asset,
        address receiver,
        uint256 assetsToDeposit
    ) external returns (uint256 newShares);

    function withdraw(
        address asset,
        address receiver,
        uint256 maxAssetsToWithdraw
    ) external returns (uint256 assetsWithdrawn);

    function swapExactIn(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address receiver,
        uint256 referralCode
    ) external returns (uint256 amountOut);

    function swapExactOut(
        address assetIn,
        address assetOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        address receiver,
        uint256 referralCode
    ) external returns (uint256 amountIn);

    function previewSwapExactIn(
        address assetIn,
        address assetOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function previewSwapExactOut(
        address assetIn,
        address assetOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn);
}
