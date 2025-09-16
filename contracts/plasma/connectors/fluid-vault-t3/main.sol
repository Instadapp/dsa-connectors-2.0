//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid Vault T3.
 * @dev Normal Collateral - Smart Debt.
 * @dev Dex.
 */

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {IVaultT3} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract FluidVaultT3Connector is Helpers, Events {
    struct OperateInternalVariables {
        uint256 xplAmount;
        int256 colShares;
        int256 debtShares;
    }

    struct OperatePerfectInternalVariables {
        uint256 xplAmount;
        bool isDebtMin;
        bool isDebtToken0Xpl;
        bool isDebtToken1Xpl;
        int256[] r;
    }

    /**
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newColToken0 Token 0 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param newColToken1 Token 1 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * No max or min values allowed. Need to send exact values.
     * @param colSharesMinMax Min or max collateral shares to mint or burn (positive for deposit, negative for withdrawal)
     * @param newDebtToken0 Token 0 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param newDebtToken1 Token 1 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param debtSharesMinMax Min or max debt shares to burn or mint (positive for borrowing, negative for repayment)
     * @param setIds Array of 7 elements to set IDs:
     * Nft Id
     * Supply amount token 0
     * Withdraw amount token 0
     * Borrow amount token 0
     * Borrow amount token 1
     * Payback amount token 0
     * Payback amount token 1
     */
    struct OperateWIthIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newCol;
        int256 newDebtToken0;
        int256 newDebtToken1;
        int256 debtSharesMinMax;
        uint256[] getIds;
        uint256[] setIds;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw assets from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param helper_ Helper struct for collateral and debt data.
     */
    function operateWithIds(
        OperateWIthIdsHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        _validateIds(helper_.getIds, helper_.setIds);
        helper_.nftId = getUint(helper_.getIds[0], helper_.nftId);
        helper_.newCol = _adjustTokenValues(
            helper_.getIds[1],
            helper_.getIds[2],
            helper_.newCol
        );
        helper_.newDebtToken0 = _adjustTokenValues(
            helper_.getIds[3],
            helper_.getIds[5],
            helper_.newDebtToken0
        );
        helper_.newDebtToken1 = _adjustTokenValues(
            helper_.getIds[4],
            helper_.getIds[6],
            helper_.newDebtToken1
        );

        IVaultT3 vaultT3_ = IVaultT3(helper_.vaultAddress);
        IVaultT3.ConstantViews memory vaultT3Details_ = vaultT3_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit (Normal Collateral)
        if (helper_.newCol > 0) {
            (internalVar_.xplAmount, helper_.newCol) = _handleDeposit(
                HandleDepositData({
                    isXpl: vaultT3Details_.supplyToken.token0 == getXplAddr(),
                    isMax: helper_.newCol == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT3Details_.supplyToken.token0,
                    colAmt: helper_.newCol
                })
            );
        }

        // Payback token 0
        if (helper_.newDebtToken0 < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: vaultT3Details_.borrowToken.token0 == getXplAddr(),
                    isMin: false,
                    token: vaultT3Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.newDebtToken0),
                    debtAmt: helper_.newDebtToken0,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        // Payback token 1
        if (helper_.newDebtToken1 < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: vaultT3Details_.borrowToken.token1 == getXplAddr(),
                    isMin: false,
                    token: vaultT3Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.newDebtToken1),
                    debtAmt: helper_.newDebtToken1,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (
            helper_.nftId,
            internalVar_.colShares,
            internalVar_.debtShares
        ) = vaultT3_.operate{value: internalVar_.xplAmount}(
            helper_.nftId,
            helper_.newCol,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            address(this)
        );

        setUint(helper_.setIds[0], helper_.nftId);
        _setIds(helper_.setIds[1], helper_.setIds[2], helper_.newCol);
        _setIds(helper_.setIds[3], helper_.setIds[5], helper_.newDebtToken0);
        _setIds(helper_.setIds[4], helper_.setIds[6], helper_.newDebtToken1);

        _eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,uint256[],uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newCol,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            helper_.getIds,
            helper_.setIds
        );
    }

    /**
     * @param vaultAddress Vault address.
     * @param nftId NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param newDebtToken0 Token 0 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param newDebtToken1 Token 1 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param debtSharesMinMax Min or max debt shares to burn or mint (positive for borrowing, negative for repayment)
     */
    struct OperateHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newCol;
        int256 newDebtToken0;
        int256 newDebtToken1;
        int256 debtSharesMinMax;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw assets from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param helper_ Helper struct for collateral and debt data.
     */
    function operate(
        OperateHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVaultT3 vaultT3_ = IVaultT3(helper_.vaultAddress);
        IVaultT3.ConstantViews memory vaultT3Details_ = vaultT3_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit (Normal Collateral)
        if (helper_.newCol > 0) {
            (internalVar_.xplAmount, helper_.newCol) = _handleDeposit(
                HandleDepositData({
                    isXpl: vaultT3Details_.supplyToken.token0 == getXplAddr(),
                    isMax: helper_.newCol == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT3Details_.supplyToken.token0,
                    colAmt: helper_.newCol
                })
            );
        }

        // Payback token 0
        if (helper_.newDebtToken0 < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: vaultT3Details_.borrowToken.token0 == getXplAddr(),
                    isMin: false,
                    token: vaultT3Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.newDebtToken0),
                    debtAmt: helper_.newDebtToken0,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        // Payback token 1
        if (helper_.newDebtToken1 < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: vaultT3Details_.borrowToken.token1 == getXplAddr(),
                    isMin: false,
                    token: vaultT3Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.newDebtToken1),
                    debtAmt: helper_.newDebtToken1,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (
            helper_.nftId,
            internalVar_.colShares,
            internalVar_.debtShares
        ) = vaultT3_.operate{value: internalVar_.xplAmount}(
            helper_.nftId,
            helper_.newCol,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            address(this)
        );

        _eventName = "LogOperate(address,uint256,int256,int256,int256,int256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newCol,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax
        );
    }

    /**
     * @param vaultAddress Vault address.
     * @param nftId NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param perfectDebtShares The change in debt shares (positive for borrowing, negative for repayment)
     * Send Min int for max payback.
     * @param debtToken0MinMax Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
     * @param debtToken1MinMax Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
     * @param getNftId Id to retrieve Nft Id
     * @param setIds Array of 7 elements to set IDs:
     *              0 - nft id
     *              1 - deposit amount
     *              2 - withdraw amount
     *              3 - token0 borrow amount
     *              4 - token0 payback amount
     *              5 - token1 borrow amount
     *              6 - token1 payback amount
     */
    struct OperatePerfectWithIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newCol;
        int256 perfectDebtShares;
        int256 debtToken0MinMax; // if +, min to borrow, if -, max to payback
        int256 debtToken1MinMax; // if +, min to borrow, if -, max to payback
        uint256 getNftId;
        uint256[] setIds;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw perfect amounts of assets from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param helper_ Helper struct for collateral and debt data.
     */
    function operatePerfectWithIds(
        OperatePerfectWithIdsHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        helper_.nftId = getUint(helper_.getNftId, helper_.nftId);
        IVaultT3 vaultT3_ = IVaultT3(helper_.vaultAddress);
        IVaultT3.ConstantViews memory vaultT3Details_ = vaultT3_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        // Deposit (Normal Collateral)
        if (helper_.newCol > 0) {
            (internalVar_.xplAmount, helper_.newCol) = _handleDeposit(
                HandleDepositData({
                    isXpl: vaultT3Details_.supplyToken.token0 == getXplAddr(),
                    isMax: helper_.newCol == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT3Details_.supplyToken.token0,
                    colAmt: helper_.newCol
                })
            );
        }

        internalVar_.isDebtMin = helper_.perfectDebtShares == type(int256).min;
        internalVar_.isDebtToken0Xpl =
            vaultT3Details_.borrowToken.token0 == getXplAddr();
        internalVar_.isDebtToken1Xpl =
            vaultT3Details_.borrowToken.token1 == getXplAddr();

        // Payback
        if (helper_.perfectDebtShares < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: internalVar_.isDebtToken0Xpl,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT3Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.debtToken0MinMax),
                    debtAmt: helper_.debtToken0MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );

            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: internalVar_.isDebtToken1Xpl,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT3Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.debtToken1MinMax),
                    debtAmt: helper_.debtToken1MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT3_.operatePerfect{
            value: internalVar_.xplAmount
        }(
            helper_.nftId,
            helper_.newCol,
            helper_.perfectDebtShares,
            helper_.debtToken0MinMax,
            helper_.debtToken1MinMax,
            address(this)
        );

        setUint(helper_.setIds[0], helper_.nftId);
        _handleOperatePerfectSetIds(
            internalVar_.r[0],
            helper_.setIds[1],
            helper_.setIds[2]
        );
        _handleOperatePerfectSetIds(
            internalVar_.r[2],
            helper_.setIds[3],
            helper_.setIds[4]
        );
        _handleOperatePerfectSetIds(
            internalVar_.r[3],
            helper_.setIds[5],
            helper_.setIds[6]
        );

        // Make approval 0
        if (internalVar_.isDebtMin) {
            if (!internalVar_.isDebtToken0Xpl) {
                approve(
                    TokenInterface(vaultT3Details_.borrowToken.token0),
                    helper_.vaultAddress,
                    0
                );
            }

            if (!internalVar_.isDebtToken1Xpl) {
                approve(
                    TokenInterface(vaultT3Details_.borrowToken.token1),
                    helper_.vaultAddress,
                    0
                );
            }
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,uint256,uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            internalVar_.r[1],
            helper_.perfectDebtShares,
            internalVar_.r[2],
            internalVar_.r[3],
            helper_.getNftId,
            helper_.setIds
        );
    }

    /**
     * @param vaultAddress Vault address.
     * @param nftId NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param perfectDebtShares The change in debt shares (positive for borrowing, negative for repayment)
     * Send Min int for max payback.
     * @param debtToken0MinMax Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
     * @param debtToken1MinMax Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
     */
    struct OperatePerfectHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newCol;
        int256 perfectDebtShares;
        int256 debtToken0MinMax; // if +, min to borrow, if -, max to payback
        int256 debtToken1MinMax; // if +, min to borrow, if -, max to payback
    }

    function operatePerfect(
        OperatePerfectHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVaultT3 vaultT3_ = IVaultT3(helper_.vaultAddress);
        IVaultT3.ConstantViews memory vaultT3Details_ = vaultT3_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        // Deposit (Normal Collateral)
        if (helper_.newCol > 0) {
            (internalVar_.xplAmount, helper_.newCol) = _handleDeposit(
                HandleDepositData({
                    isXpl: vaultT3Details_.supplyToken.token0 == getXplAddr(),
                    isMax: helper_.newCol == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT3Details_.supplyToken.token0,
                    colAmt: helper_.newCol
                })
            );
        }

        internalVar_.isDebtMin = helper_.perfectDebtShares == type(int256).min;
        internalVar_.isDebtToken0Xpl =
            vaultT3Details_.borrowToken.token0 == getXplAddr();
        internalVar_.isDebtToken1Xpl =
            vaultT3Details_.borrowToken.token1 == getXplAddr();

        // Payback
        if (helper_.perfectDebtShares < 0) {
            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: internalVar_.isDebtToken0Xpl,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT3Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.debtToken0MinMax),
                    debtAmt: helper_.debtToken0MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );

            internalVar_.xplAmount = _handlePayback(
                HandlePaybackData({
                    isXpl: internalVar_.isDebtToken1Xpl,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT3Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.debtToken1MinMax),
                    debtAmt: helper_.debtToken1MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT3_.operatePerfect{
            value: internalVar_.xplAmount
        }(
            helper_.nftId,
            helper_.newCol,
            helper_.perfectDebtShares,
            helper_.debtToken0MinMax,
            helper_.debtToken1MinMax,
            address(this)
        );

        // Make approval 0
        if (internalVar_.isDebtMin) {
            if (!internalVar_.isDebtToken0Xpl) {
                approve(
                    TokenInterface(vaultT3Details_.borrowToken.token0),
                    helper_.vaultAddress,
                    0
                );
            }

            if (!internalVar_.isDebtToken1Xpl) {
                approve(
                    TokenInterface(vaultT3Details_.borrowToken.token1),
                    helper_.vaultAddress,
                    0
                );
            }
        }

        _eventName = "LogOperatePerfect(address,uint256,int256,int256,int256,int256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            internalVar_.r[1],
            helper_.perfectDebtShares,
            internalVar_.r[2],
            internalVar_.r[3]
        );
    }
}

contract ConnectV2FluidVaultT3 is FluidVaultT3Connector {
    string public constant name = "Fluid-vaultT3-v1.0";
}
