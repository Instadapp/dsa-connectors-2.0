// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IFluidDexV2 {
    function operate(
        uint256 nftId_,
        uint256 positionIndex_,
        bytes calldata actionData_
    ) external payable returns (uint256, uint256);

    function changeEmode(uint256 nftId_, uint256 newEmode_) external payable;
}

struct PositionParams {
    uint256 token0Index;
    uint256 token1Index;
    uint24 tickSpacing;
    uint24 fee;
    address controller;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0;
    uint256 amount1;
    uint256 amount0Min;
    uint256 amount1Min;
    address to;
}

struct OperateWithIdsVariables {
    uint256 operateCollateralAmount0;
    uint256 operateCollateralAmount1;
    uint256 operateDebtAmount0;
    uint256 operateDebtAmount1;
}

struct TokenAddressParams {
    address token0Address;
    address token1Address;
}

struct ApproveAmountParams {
    uint256 approveAmount0;
    uint256 approveAmount1;
}
