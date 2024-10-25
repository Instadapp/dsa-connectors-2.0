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

    struct OperatePerfectInternalVariables {
        uint256 ethAmount;
        bool isDebtMin;
        bool isDebtTokenEth;
        int256[] r;
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

    struct OperatePerfectWithIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 perfectColShares;
        int256 colToken0MinMax; // if +, max to deposit, if -, min to withdraw
        int256 colToken1MinMax; // if +, max to deposit, if -, min to withdraw
        int256 newDebt_;
        uint256 repayApproveAmt_;
        uint256 getNftId;
        uint256[] setIds;
    }

    function operatePerfectWithIds(
        OperatePerfectWithIdsHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        helper_.nftId = getUint(helper_.getNftId, helper_.nftId);
        IVaultT2 vaultT2_ = IVaultT2(helper_.vaultAddress);
        IVaultT2.ConstantViews memory vaultT2Details_ = vaultT2_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        // Deposit
        if (helper_.perfectColShares > 0) {
            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token0,
                    colAmt: helper_.colToken0MinMax
                })
            );

            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token1,
                    colAmt: helper_.colToken1MinMax
                })
            );
        }

        internalVar_.isDebtMin = helper_.newDebt_ == type(int256).min;
        internalVar_.isDebtTokenEth =
            vaultT2Details_.borrowToken.token0 == getEthAddr();

        // Payback
        if (helper_.newDebt_ < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtTokenEth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT2Details_.borrowToken.token0,
                    repayApproveAmt: helper_.repayApproveAmt_,
                    debtAmt: helper_.newDebt_,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT2_.operatePerfect{
            value: internalVar_.ethAmount
        }(
            helper_.nftId,
            helper_.perfectColShares,
            helper_.colToken0MinMax,
            helper_.colToken1MinMax,
            helper_.newDebt_,
            address(this)
        );

        setUint(helper_.setIds[0], helper_.nftId);
        _handleOperatePerfectSetIds(
            internalVar_.r[1],
            helper_.setIds[1],
            helper_.setIds[2]
        );
        _handleOperatePerfectSetIds(
            internalVar_.r[2],
            helper_.setIds[3],
            helper_.setIds[4]
        );
        _handleOperatePerfectSetIds(
            internalVar_.r[4],
            helper_.setIds[5],
            helper_.setIds[6]
        );

        // Make approval 0
        if (internalVar_.isDebtMin && !internalVar_.isDebtTokenEth) {
            approve(
                TokenInterface(vaultT2Details_.borrowToken.token0),
                helper_.vaultAddress,
                0
            );
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.perfectColShares,
            internalVar_.r[1],
            internalVar_.r[2],
            internalVar_.r[4],
            helper_.repayApproveAmt_,
            helper_.getNftId,
            helper_.setIds
        );
    }

    struct OperatePerfectHelper {
        address vaultAddress;
        uint256 nftId;
        int256 perfectColShares;
        int256 colToken0MinMax; // if +, max to deposit, if -, min to withdraw
        int256 colToken1MinMax; // if +, max to deposit, if -, min to withdraw
        int256 newDebt_;
        uint256 repayApproveAmt_;
    }

    function operatePerfect(
        OperatePerfectHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVaultT2 vaultT2_ = IVaultT2(helper_.vaultAddress);
        IVaultT2.ConstantViews memory vaultT2Details_ = vaultT2_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        // Deposit
        if (helper_.perfectColShares > 0) {
            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token0,
                    colAmt: helper_.colToken0MinMax
                })
            );

            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT2Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT2Details_.supplyToken.token1,
                    colAmt: helper_.colToken1MinMax
                })
            );
        }

        internalVar_.isDebtMin = helper_.newDebt_ == type(int256).min;
        internalVar_.isDebtTokenEth =
            vaultT2Details_.borrowToken.token0 == getEthAddr();

        // Payback
        if (helper_.newDebt_ < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtTokenEth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT2Details_.borrowToken.token0,
                    repayApproveAmt: helper_.repayApproveAmt_,
                    debtAmt: helper_.newDebt_,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT2_.operatePerfect{
            value: internalVar_.ethAmount
        }(
            helper_.nftId,
            helper_.perfectColShares,
            helper_.colToken0MinMax,
            helper_.colToken1MinMax,
            helper_.newDebt_,
            address(this)
        );

        // Make approval 0
        if (internalVar_.isDebtMin && !internalVar_.isDebtTokenEth) {
            approve(
                TokenInterface(vaultT2Details_.borrowToken.token0),
                helper_.vaultAddress,
                0
            );
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,uint256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.perfectColShares,
            internalVar_.r[1],
            internalVar_.r[2],
            internalVar_.r[4],
            helper_.repayApproveAmt_
        );
    }
}

contract ConnectV2FluidVaultT2 is FluidVaultT2Connector {
    string public constant name = "Fluid-vaultT2-v1.0";
}
