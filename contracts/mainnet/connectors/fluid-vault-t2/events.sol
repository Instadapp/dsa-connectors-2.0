//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogOperateWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newColToken0,
        int256 newColToken1,
        int256 colSharesMinMax,
        int256 newDebt,
        uint256 repayApproveAmt,
        uint256[] getIds,
        uint256[] setIds
    );

    event LogOperate(
        address vaultAddress,
        uint256 nftId,
        int256 newColToken0,
        int256 newColToken1,
        int256 colSharesMinMax,
        int256 newDebt,
        uint256 repayApproveAmt
    );

    event LogOperatePerfectWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 perfectColShares,
        int256 token0DepositOrWithdraw,
        int256 token1DepositOrWithdraw,
        int256 newDebt,
        uint256 repayApproveAmt,
        uint256 getNftId,
        uint256[] setIds
    );

    event LogOperatePerfect(
        address vaultAddress,
        uint256 nftId,
        int256 perfectColShares,
        int256 token0DepositOrWithdraw,
        int256 token1DepositOrWithdraw,
        int256 newDebt,
        uint256 repayApproveAmt
    );
}
