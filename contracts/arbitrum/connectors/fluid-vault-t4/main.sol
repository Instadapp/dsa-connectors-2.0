//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid Vault T4.
 * @dev Dex.
 */

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {IVaultT4} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract FluidVaultT4Connector is Helpers, Events {

    /**
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newColToken0_ Token 0 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param newColToken1_ Token 1 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * No max or min values allowed. Need to send exact values.
     * @param colSharesMinMax_ Min or max collateral shares to mint or burn (positive for deposit, negative for withdrawal)
     * @param newDebtToken0_ Token 0 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param newDebtToken1_ Token 1 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param debtSharesMinMax_ Min or max debt shares to burn or mint (positive for borrowing, negative for repayment)
     * @param setIds_ Array of 9 elements to set IDs:
     * Nft Id
     * Supply amount token 0
     * Supply amount token 1
     * Withdraw amount token 0
     * Withdraw amount token 1
     * Borrow amount token 0
     * Borrow amount token 1
     * Payback amount token 0
     * Payback amount token 1
     */
    struct OperateWIthIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newColToken0;
        int256 newColToken1;
        int256 colSharesMinMax;
        int256 newDebtToken0;
        int256 newDebtToken1;
        int256 debtSharesMinMax;
        uint256[] getIds;
        uint256[] setIds;
    }

    struct OperateInternalVariables {
        uint256 ethAmount;
        int256 colShares;
        int256 debtShares;
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
        helper_.newDebtToken0 = _adjustTokenValues(
            helper_.getIds[5],
            helper_.getIds[7],
            helper_.newDebtToken0
        );
        helper_.newDebtToken1 = _adjustTokenValues(
            helper_.getIds[6],
            helper_.getIds[8],
            helper_.newDebtToken1
        );

        IVaultT4 vaultT4_ = IVaultT4(helper_.vaultAddress);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit token 0
        if (helper_.newColToken0 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken0) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.newColToken0 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token0,
                    colAmt: helper_.newColToken0
                })
            );
        }

        // Deposit token 1
        if (helper_.newColToken1 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken1) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.newColToken1 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token1,
                    colAmt: helper_.newColToken1
                })
            );
        }

        // Payback token 0
        if (helper_.newDebtToken0 < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT4Details_.borrowToken.token0 == getEthAddr(),
                    isMin: false,
                    token: vaultT4Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.newDebtToken0),
                    debtAmt: helper_.newDebtToken0,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        // Payback token 1
        if (helper_.newDebtToken1 < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT4Details_.borrowToken.token1 == getEthAddr(),
                    isMin: false,
                    token: vaultT4Details_.borrowToken.token1,
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
        ) = vaultT4_.operate{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            address(this)
        );

        setUint(helper_.setIds[0], helper_.nftId);
        _setIds(
            helper_.setIds[1],
            helper_.setIds[3],
            helper_.newColToken0
        );
        _setIds(
            helper_.setIds[2],
            helper_.setIds[4],
            helper_.newColToken1
        );
        _setIds(
            helper_.setIds[5],
            helper_.setIds[7],
            helper_.newDebtToken0
        );
        _setIds(
            helper_.setIds[6],
            helper_.setIds[8],
            helper_.newDebtToken1
        );

        _eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            helper_.getIds,
            helper_.setIds
        );
    }

    /**
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newColToken0_ Token 0 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param newColToken1_ Token 1 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * No max or min values allowed. Need to send exact values.
     * @param colSharesMinMax_ Min or max collateral shares to mint or burn (positive for deposit, negative for withdrawal)
     * @param newDebtToken0_ Token 0 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param newDebtToken1_ Token 1 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param debtSharesMinMax_ Min or max debt shares to burn or mint (positive for borrowing, negative for repayment)
    */
    struct OperateHelper {
        address vaultAddress;
        uint256 nftId;
        int256 newColToken0;
        int256 newColToken1;
        int256 colSharesMinMax;
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
        IVaultT4 vaultT4_ = IVaultT4(helper_.vaultAddress);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_
            .constantsView();

        OperateInternalVariables memory internalVar_;

        // Deposit token 0
        if (helper_.newColToken0 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken0) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.newColToken0 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token0,
                    colAmt: helper_.newColToken0
                })
            );
        }

        // Deposit token 1
        if (helper_.newColToken1 > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (internalVar_.ethAmount, helper_.newColToken1) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.newColToken1 == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token1,
                    colAmt: helper_.newColToken1
                })
            );
        }

        // Payback token 0
        if (helper_.newDebtToken0 < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT4Details_.borrowToken.token0 == getEthAddr(),
                    isMin: false,
                    token: vaultT4Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.newDebtToken0),
                    debtAmt: helper_.newDebtToken0,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        // Payback token 1
        if (helper_.newDebtToken1 < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: vaultT4Details_.borrowToken.token1 == getEthAddr(),
                    isMin: false,
                    token: vaultT4Details_.borrowToken.token1,
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
        ) = vaultT4_.operate{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax,
            address(this)
        );

        _eventName = "LogOperate(address,uint256,int256,int256,int256,int256,int256,int256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.newColToken0,
            helper_.newColToken1,
            helper_.colSharesMinMax,
            helper_.newDebtToken0,
            helper_.newDebtToken1,
            helper_.debtSharesMinMax
        );
    }

    /**
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param perfectColShares_ The change in collateral shares (positive for deposit, negative for withdrawal)
     * Send Min int for max withdraw.
     * @param colToken0MinMax_ Min or max collateral amount of token0 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param colToken1MinMax_ Min or max collateral amount of token1 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param perfectDebtShares_ The change in debt shares (positive for borrowing, negative for repayment)
     * Send Min int for max payback.
     * @param debtToken0MinMax_ Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
     * @param debtToken1MinMax_ Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
     * @param getNftId_ Id to retrieve Nft Id
     * @param setIds_ Array of 9 elements to set IDs:
     *              0 - nft id
     *              1 - token0 deposit amount
     *              2 - token0 withdraw amount
     *              3 - token1 deposit amount
     *              4 - token1 withdraw amount
     *              5 - token0 borrow amount
     *              6 - token0 payback amount
     *              7 - token1 borrow amount
     *              8 - token1 payback amount
     */
    struct OperatePerfectWIthIdsHelper {
        address vaultAddress;
        uint256 nftId;
        int256 perfectColShares;
        int256 colToken0MinMax; // if +, max to deposit, if -, min to withdraw
        int256 colToken1MinMax; // if +, max to deposit, if -, min to withdraw
        int256 perfectDebtShares;
        int256 debtToken0MinMax; // if +, min to borrow, if -, max to payback
        int256 debtToken1MinMax; // if +, min to borrow, if -, max to payback
        uint256 getNftId;
        uint256[] setIds;
    }

    struct OperatePerfectInternalVariables {
        uint256 ethAmount;
        bool isDebtMin;
        bool isDebtToken0Eth;
        bool isDebtToken1Eth;
        int256[] r;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw perfect amounts of assets from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param helper_ Helper struct for collateral and debt data.
     */
    function operatePerfectWithIds(
        OperatePerfectWIthIdsHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        helper_.nftId = getUint(helper_.getNftId, helper_.nftId);
        IVaultT4 vaultT4_ = IVaultT4(helper_.vaultAddress);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        if (helper_.perfectColShares > 0) {
            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token0,
                    colAmt: helper_.colToken0MinMax
                })
            );

            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token1,
                    colAmt: helper_.colToken1MinMax
                })
            );
        }

        internalVar_.isDebtMin = helper_.perfectDebtShares == type(int256).min;
        internalVar_.isDebtToken0Eth =
            vaultT4Details_.borrowToken.token0 == getEthAddr();
        internalVar_.isDebtToken1Eth =
            vaultT4Details_.borrowToken.token1 == getEthAddr();

        // Payback
        if (helper_.perfectDebtShares < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtToken0Eth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT4Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.debtToken0MinMax),
                    debtAmt: helper_.debtToken0MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );

            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtToken1Eth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT4Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.debtToken1MinMax),
                    debtAmt: helper_.debtToken1MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT4_.operatePerfect{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.perfectColShares,
            helper_.colToken0MinMax,
            helper_.colToken1MinMax,
            helper_.perfectDebtShares,
            helper_.debtToken0MinMax,
            helper_.debtToken1MinMax,
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
        _handleOperatePerfectSetIds(
            internalVar_.r[5],
            helper_.setIds[7],
            helper_.setIds[8]
        );

        // Make approval 0
        if (internalVar_.isDebtMin) {
            if (!internalVar_.isDebtToken0Eth) {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token0),
                    helper_.vaultAddress,
                    0
                );
            }

            if (!internalVar_.isDebtToken1Eth) {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token1),
                    helper_.vaultAddress,
                    0
                );
            }
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.perfectColShares,
            internalVar_.r[1],
            internalVar_.r[2],
            helper_.perfectDebtShares,
            internalVar_.r[4],
            internalVar_.r[5],
            helper_.getNftId,
            helper_.setIds
        );
    }

    /**
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param perfectColShares_ The change in collateral shares (positive for deposit, negative for withdrawal)
     * Send Min int for max withdraw.
     * @param colToken0MinMax_ Min or max collateral amount of token0 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param colToken1MinMax_ Min or max collateral amount of token1 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param perfectDebtShares_ The change in debt shares (positive for borrowing, negative for repayment)
     * Send Min int for max payback.
     * @param debtToken0MinMax_ Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
     * @param debtToken1MinMax_ Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
     */
    struct OperatePerfectHelper {
        address vaultAddress;
        uint256 nftId;
        int256 perfectColShares;
        int256 colToken0MinMax; // if +, max to deposit, if -, min to withdraw
        int256 colToken1MinMax; // if +, max to deposit, if -, min to withdraw
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
    function operatePerfect(
        OperatePerfectHelper memory helper_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVaultT4 vaultT4_ = IVaultT4(helper_.vaultAddress);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_
            .constantsView();

        OperatePerfectInternalVariables memory internalVar_;

        if (helper_.perfectColShares > 0) {
            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token0 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token0,
                    colAmt: helper_.colToken0MinMax
                })
            );

            (internalVar_.ethAmount, ) = _handleDeposit(
                HandleDepositData({
                    isEth: vaultT4Details_.supplyToken.token1 == getEthAddr(),
                    isMax: helper_.perfectColShares == type(int256).max,
                    vaultAddress: helper_.vaultAddress,
                    token: vaultT4Details_.supplyToken.token1,
                    colAmt: helper_.colToken1MinMax
                })
            );
        }

        internalVar_.isDebtMin = helper_.perfectDebtShares == type(int256).min;
        internalVar_.isDebtToken0Eth =
            vaultT4Details_.borrowToken.token0 == getEthAddr();
        internalVar_.isDebtToken1Eth =
            vaultT4Details_.borrowToken.token1 == getEthAddr();

        // Payback
        if (helper_.perfectDebtShares < 0) {
            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtToken0Eth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT4Details_.borrowToken.token0,
                    repayApproveAmt: uint256(-helper_.debtToken0MinMax),
                    debtAmt: helper_.debtToken0MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );

            internalVar_.ethAmount = _handlePayback(
                HandlePaybackData({
                    isEth: internalVar_.isDebtToken1Eth,
                    isMin: internalVar_.isDebtMin,
                    token: vaultT4Details_.borrowToken.token1,
                    repayApproveAmt: uint256(-helper_.debtToken1MinMax),
                    debtAmt: helper_.debtToken1MinMax,
                    vaultAddress: helper_.vaultAddress
                })
            );
        }

        (helper_.nftId, internalVar_.r) = vaultT4_.operatePerfect{value: internalVar_.ethAmount}(
            helper_.nftId,
            helper_.perfectColShares,
            helper_.colToken0MinMax,
            helper_.colToken1MinMax,
            helper_.perfectDebtShares,
            helper_.debtToken0MinMax,
            helper_.debtToken1MinMax,
            address(this)
        );

        // Make approval 0
        if (internalVar_.isDebtMin) {
            if (!internalVar_.isDebtToken0Eth) {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token0),
                    helper_.vaultAddress,
                    0
                );
            }

            if (!internalVar_.isDebtToken1Eth) {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token1),
                    helper_.vaultAddress,
                    0
                );
            }
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256)";
        _eventParam = abi.encode(
            helper_.vaultAddress,
            helper_.nftId,
            helper_.perfectColShares,
            internalVar_.r[1],
            internalVar_.r[2],
            helper_.perfectDebtShares,
            internalVar_.r[4],
            internalVar_.r[5]
        );
    }
}

contract ConnectV2FluidVaultT4Arbitrum is FluidVaultT4Connector {
    string public constant name = "Fluid-vaultT4-v1.0";
}
