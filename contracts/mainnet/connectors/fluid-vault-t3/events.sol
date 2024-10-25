//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogOperateWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newCol_,
        int256 newDebtToken0,
        int256 newDebtToken1,
        int256 debtSharesMinMax,
        uint256[] getIds,
        uint256[] setIds
    );

    event LogOperate(
        address vaultAddress,
        uint256 nftId,
        int256 newCol_,
        int256 newDebtToken0,
        int256 newDebtToken1,
        int256 debtSharesMinMax
    );

    event LogOperatePerfectWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newCol_,
        int256 perfectDebtShares_,
        int256 token0BorrowOrPayback,
        int256 token1BorrowOrPayback,
        uint256 getNftId_,
        uint256[] setIds
    );

    event LogOperatePerfect(
        address vaultAddress,
        uint256 nftId,
        int256 newCol_,
        int256 perfectDebtShares_,
        int256 token0BorrowOrPayback,
        int256 token1BorrowOrPayback
    );
}
