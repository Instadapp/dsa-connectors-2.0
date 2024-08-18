//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Events {
    event LogDeposit(
        address asset,
        uint256 assetAmount,
        uint256 minShares,
        uint256 sharesMinted,
        uint256 getId,
        uint256 setId
    );
}
