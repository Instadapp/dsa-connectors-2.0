//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {

    event LogOperateWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newColToken0,
        int256 newColToken1,
        int256 colSharesMinMax,
        int256 newDebtToken0,
        int256 newDebtToken1,
        int256 debtSharesMinMax,
        uint256 repayApproveAmtToken0,
        uint256 repayApproveAmtToken1,
        uint256[] getIds,
        uint256[] setIds
    );

    event LogOperatePerfectWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 perfectColShares_,
        int256 token0DepositOrWithdraw,
        int256 token1DepositOrWithdraw,
        int256 perfectDebtShares_,
        int256 token0BorrowOrPayback,
        int256 token1BorrowOrPayback,
        uint256 getNftId_,
        uint256[] setIds
    );
}
