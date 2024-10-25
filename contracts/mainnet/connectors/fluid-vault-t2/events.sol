//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogOperateWithIds(
        address vaultAddress,
        uint256 nftId,
        int256 newColToken0,
        int256 newColToken1,
        int256 colSharesMinMax,
        int256 newDebt_,
        uint256 repayApproveAmt_,
        uint256[] getIds,
        uint256[] setIds
    );

    event LogOperate(
        address vaultAddress,
        uint256 nftId,
        int256 newColToken0,
        int256 newColToken1,
        int256 colSharesMinMax,
        int256 newDebt_,
        uint256 repayApproveAmt_
    );
}
