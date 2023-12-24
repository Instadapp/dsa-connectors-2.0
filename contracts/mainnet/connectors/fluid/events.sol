//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogOperate (
        address vaultAddress,
        uint256 nftId,
        int256 newCol,
        int256 newDebt,
        address to,
		uint256 getId,
		uint256 setId
    );
}