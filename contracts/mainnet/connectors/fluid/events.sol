//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogOperate(
        address vaultAddress,
        uint256 nftId,
        int256 newCol,
        int256 newDebt
    );

    event LogOperateWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newCol,
        int256 newDebt,
        uint256[] getIds,
        uint256[] setIds
    );
}
