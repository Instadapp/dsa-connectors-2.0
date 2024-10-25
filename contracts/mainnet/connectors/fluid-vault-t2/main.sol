//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid Vault T2.
 * @dev Smart Collateral - Normal Debt.
 * @dev Dex.
 */

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {IVaultT2} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract FluidVaultT2Connector is Helpers, Events {
    struct OperateInternalVariables {
        uint256 ethAmount;
        int256 colShares;
        int256 debtShares;
    }

    struct OperateWIthIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newColToken0;
        int256 newColToken1;
        int256 colSharesMinMax;
        int256 newDebt_;
        uint256 repayApproveAmt_;
        uint256[] getIds;
        uint256[] setIds;
    }

    function operateWithIds(
        OperateWIthIdsHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        _validateIds(helper_.getIds, helper_.setIds);
        helper_.nftId = getUint(helper_.getIds[0], helper_.nftId);
        helper_.newColToken0 = _adjustTokenValues(
            helper_.getIds[1],
            helper_.getIds[3],
            helper_.newColToken0
        );
        helper_.newColToken1 = _adjustTokenValues(
            helper_.getIds[2],
            helper_.getIds[4],
            helper_.newColToken1
        );
        helper_.newDebt_ = _adjustTokenValues(
            helper_.getIds[5],
            helper_.getIds[7],
            helper_.newDebt_
        );

        IVaultT2 vaultT2_ = IVaultT2(helper_.vaultAddress);
        IVaultT2.ConstantViews memory vaultT2Details_ = vaultT2_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit token 0
        if (helper_.newColToken0 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken0) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.newColToken0 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token0,
                    colAmt: helper_.newColToken0
                })
            );
        }

        // Deposit token 1
        if (helper_.newColToken1 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken1) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.newColToken1 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token1,
                    colAmt: helper_.newColToken1
                })
            );
        }

        // Payback (Normal Debt)
        if (helper_.newDebt_ < 0) {
            (internalVar_.ethAmount) = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT2Details_.borrowToken.token0 == getEthAddr(),
                    isMin: helper_.newDebt_ == type(int256).min,
                    token: vaultT2Details_.borrowToken.token0,
                    repayApproveAmt: helper_.repayApproveAmt_,
                    debtAmt: helper_.newDebt_,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (
            helper_.nftId,
            internalVar_.colShares,
            internalVar_.debtShares
        ) = vaultT2_.operate{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebt_,
            address(this)
        );

        setUint(helper_.setIds[0], helper_.nftId);
        _setIds(helper_.setIds[1], helper_.setIds[3], helper_.newColToken0);
        _setIds(helper_.setIds[2], helper_.setIds[4], helper_.newColToken1);
        _setIds(helper_.setIds[5], helper_.setIds[7], helper_.newDebt_);

        _eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebt_,
            helper_.repayApproveAmt_,
            helper_.getIds,
            helper_.setIds
        );
    }

    struct OperateHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newColToken0;
        int256 newColToken1;
        int256 colSharesMinMax;
        int256 newDebt_;
        uint256 repayApproveAmt_;
    }

    function operate(
        OperateHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVaultT2 vaultT2_ = IVaultT2(helper_.vaultAddress);
        IVaultT2.ConstantViews memory vaultT2Details_ = vaultT2_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit token 0
        if (helper_.newColToken0 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken0) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.newColToken0 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token0,
                    colAmt: helper_.newColToken0
                })
            );
        }

        // Deposit token 1
        if (helper_.newColToken1 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken1) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.newColToken1 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token1,
                    colAmt: helper_.newColToken1
                })
            );
        }

        // Payback (Normal Debt)
        if (helper_.newDebt_ < 0) {
            (internalVar_.ethAmount) = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT2Details_.borrowToken.token0 == getEthAddr(),
                    isMin: helper_.newDebt_ == type(int256).min,
                    token: vaultT2Details_.borrowToken.token0,
                    repayApproveAmt: helper_.repayApproveAmt_,
                    debtAmt: helper_.newDebt_,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (
            helper_.nftId,
            internalVar_.colShares,
            internalVar_.debtShares
        ) = vaultT2_.operate{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebt_,
            address(this)
        );

        _eventName = "LogOperate(address,uint256,int256,int256,int256,int256, uint256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebt_,
            helper_.repayApproveAmt_
        );
    }

    function operatePerfectWithIds()
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {}

    function operatePerfect()
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {}
}

contract ConnectV2FluidVaultT2 is FluidVaultT2Connector {
    string public constant name = "Fluid-vaultT2-v1.0";
}
