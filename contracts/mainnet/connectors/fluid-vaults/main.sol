//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid.
 * @dev Lending & Borrowing.
 */

import {Helpers} from "./helpers.sol";
import {TokenInterface} from "../../common/interfaces.sol";

import {Events} from "./events.sol";
import {IVaultT4} from "./interface.sol";

abstract contract FluidConnector is Helpers, Events {

    /**
     * @dev Deposit, borrow, payback and withdraw asset from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newColToken0_ Token 0 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * @param newColToken1_ Token 1 new collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * For max deposit use type(uint25).max, for max withdraw use type(uint25).min.
     * @param colSharesMinMax_ Min or max collateral shares to mint or burn (positive for deposit, negative for withdrawal)
     * @param newDebtToken0_ Token 0 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * @param newDebtToken1_ Token 1 new debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * For max payback use type(uint25).min.
     * @param debtSharesMinMax_ Min or max debt shares to burn or mint (positive for borrowing, negative for repayment)
     * @param repayApproveAmtToken0_ In case of max amount for payback, this amount will be approved for token 0 spending.
     * @param repayApproveAmtToken1_ In case of max amount for payback, this amount will be approved for token 1 spending.
     * Should always be positive.
     * @param getIds_ Array of 9 elements to retrieve IDs:
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
    function operateWithIds(
        address vaultAddress_,
        uint256 nftId_,
        int256 newColToken0_,
        int256 newColToken1_,
        int256 colSharesMinMax_,
        int256 newDebtToken0_,
        int256 newDebtToken1_,
        int256 debtSharesMinMax_,
        uint256 repayApproveAmtToken0_,
        uint256 repayApproveAmtToken1_,
        uint256[] memory getIds_,
        uint256[] memory setIds_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        _validateIds(getIds_, setIds_);
        nftId_ = getUint(getIds_[0], nftId_);
        newColToken0_ = _adjustTokenValues(getIds_[1], getIds_[3], newColToken0_);
        newColToken1_ = _adjustTokenValues(getIds_[2], getIds_[4], newColToken1_);
        newDebtToken0_ = _adjustTokenValues(getIds_[5], getIds_[7], newDebtToken0_);
        newDebtToken1_ = _adjustTokenValues(getIds_[6], getIds_[8], newDebtToken1_);

        IVaultT4 vaultT4_ = IVaultT4(vaultAddress_);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_.constantsView();
        uint256 ethAmount_;

        // Deposit token 0
        if (newColToken0_ > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (ethAmount_, newColToken0_) = 
                _handleDeposit(
                    vaultT4Details_.supplyToken.token0 == getEthAddr(), 
                    newColToken0_ == type(int256).max, 
                    vaultAddress_, 
                    vaultT4Details_.supplyToken.token0, 
                    newColToken0_
                );
        }

        // Deposit token 1
        if (newColToken1_ > 0) {
            // Assumes ethAmount_ would either be token0 or token1
            (ethAmount_, newColToken1_) = 
                _handleDeposit(
                    vaultT4Details_.supplyToken.token1 == getEthAddr(), 
                    newColToken1_ == type(int256).max, 
                    vaultAddress_, 
                    vaultT4Details_.supplyToken.token1, 
                    newColToken1_
                );
        }

        // Payback token 0
        if (newDebtToken0_ < 0) {
            ethAmount_ = _handlePayback(
                vaultT4Details_.borrowToken.token0 == getEthAddr(),
                newDebtToken0_ == type(int256).min,
                vaultT4Details_.borrowToken.token0,
                repayApproveAmtToken0_,
                newDebtToken0_,
                vaultAddress_
            );
        }

        // Payback token 1
        if (newDebtToken1_ < 0) {
            ethAmount_ = _handlePayback(
                vaultT4Details_.borrowToken.token1 == getEthAddr(),
                newDebtToken1_ == type(int256).min,
                vaultT4Details_.borrowToken.token1,
                repayApproveAmtToken1_,
                newDebtToken1_,
                vaultAddress_
            );
        }

        int256 colShares;
        int256 debtShares;

        // Note max withdraw will be handled by Fluid contract
        (nftId_, colShares, debtShares) = vaultT4_.operate{value: ethAmount_}(
            nftId_,
            newColToken0_,
            newColToken1_,
            colSharesMinMax_,
            newDebtToken0_,
            newDebtToken1_,
            debtSharesMinMax_,
            address(this)
        );

        setUint(setIds_[0], nftId_);

        _setIds(setIds_[1], setIds_[3], uint256(newColToken0_));
        _setIds(setIds_[2], setIds_[4], uint256(newColToken1_));
        _setIds(setIds_[5], setIds_[7], uint256(newDebtToken0_));
        _setIds(setIds_[6], setIds_[8], uint256(newDebtToken1_));

        _eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256,uint256[],uint256[])";
        _eventParam = abi.encode(
            vaultAddress_,
            nftId_,
            newColToken0_,
            newColToken1_,
            colSharesMinMax_,
            newDebtToken0_,
            newDebtToken1_,
            debtSharesMinMax_,
            repayApproveAmtToken0_,
            repayApproveAmtToken1_,
            getIds_,
            setIds_
        );
    }

    /**
     * @dev Deposit, borrow, payback and withdraw asset from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param perfectColShares_ The change in collateral shares (positive for deposit, negative for withdrawal)
     * @param colToken0MinMax_ Min or max collateral amount of token0 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param colToken1MinMax_ Min or max collateral amount of token1 to withdraw or deposit (positive for deposit, negative for withdrawal)
     * @param perfectDebtShares_ The change in debt shares (positive for borrowing, negative for repayment)
     * @param debtToken0MinMax_ Min or max debt amount for token0 to borrow or payback (positive for borrowing, negative for repayment)
     * @param debtToken1MinMax_ Min or max debt amount for token1 to borrow or payback (positive for borrowing, negative for repayment)
     * @param getNftId_ Id to retrieve Nft Id
     * @param setIds_ Array of 9 elements to set IDs:
     *              0 - nft id
     *              1 - final col shares amount
     *              2 - token0 deposit or withdraw amount
     *              3 - token1 deposit or withdraw amount
     *              4 - final debt shares amount
     *              5 - token0 borrow or payback amount
     *              6 - token1 borrow or payback amount
    */
    function operatePerfectWithIds(
        address vaultAddress_,
        uint256 nftId_,
        int256 perfectColShares_,
        int256 colToken0MinMax_, // if +, max to deposit, if -, min to withdraw
        int256 colToken1MinMax_, // if +, max to deposit, if -, min to withdraw
        int256 perfectDebtShares_,
        int256 debtToken0MinMax_, // if +, min to borrow, if -, max to payback
        int256 debtToken1MinMax_, // if +, min to borrow, if -, max to payback
        uint256 getNftId_,
        uint256[] memory setIds_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        nftId_ = getUint(getNftId_, nftId_);
        IVaultT4 vaultT4_ = IVaultT4(vaultAddress_);
        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_.constantsView();
        uint256 ethAmount_;

        if (perfectColShares_ > 0) {
            (ethAmount_, ) = _handleDeposit(
                vaultT4Details_.supplyToken.token0 == getEthAddr(),
                false,
                vaultAddress_,
                vaultT4Details_.supplyToken.token0,
                colToken0MinMax_
            );

            (ethAmount_, ) = _handleDeposit(
                vaultT4Details_.supplyToken.token1 == getEthAddr(),
                false,
                vaultAddress_,
                vaultT4Details_.supplyToken.token1,
                colToken1MinMax_
            );
        }

        // Payback
        if (perfectDebtShares_ < 0) {
            ethAmount_ = _handlePayback(
                vaultT4Details_.borrowToken.token0 == getEthAddr(),
                false,
                vaultT4Details_.borrowToken.token0,
                0, // Not needed since isMin is always false
                debtToken0MinMax_,
                vaultAddress_
            );

            ethAmount_ = _handlePayback(
                vaultT4Details_.borrowToken.token1 == getEthAddr(),
                false,
                vaultT4Details_.borrowToken.token1,
                0, // Not needed since isMin is always false
                debtToken1MinMax_,
                vaultAddress_
            );
        }

        int256[] memory r_;

        (nftId_, r_) = vaultT4_.operatePerfect(
            nftId_,
            perfectColShares_,
            colToken0MinMax_,
            colToken1MinMax_,
            perfectDebtShares_,
            debtToken0MinMax_,
            debtToken1MinMax_,
            address(this)
        );

        setUint(setIds_[0], nftId_);
        // r_[0] > 0 ? setUint(setIds_[1], uint256(r_[0])) : r_[0] < 0 ? setUint(setIds_[2], uint256(r_[0])) : 0;

        if (r_[2] > 0) {
            setUint(setIds_[1], uint256(r_[2]));
        } else {
            if (r_[2] < 0) {
                setUint(setIds_[2], uint256(r_[2]));
            }
        }

        if (r_[3] > 0) {
            setUint(setIds_[3], uint256(r_[3]));
        } else {
            if (r_[3] < 0) {
                setUint(setIds_[4], uint256(r_[3]));
            }
        }

        if (r_[5] > 0) {
            setUint(setIds_[5], uint256(r_[5]));
        } else {
            if (r_[5] < 0) {
                setUint(setIds_[6], uint256(r_[5]));
            }
        }

        if (r_[6] > 0) {
            setUint(setIds_[7], uint256(r_[6]));
        } else {
            if (r_[6] < 0) {
                setUint(setIds_[8], uint256(r_[6]));
            }
        }

        _eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
        _eventParam = abi.encode(
            vaultAddress_,
            nftId_,
            perfectColShares_,
            r_[2],
            r_[3],
            perfectDebtShares_,
            r_[5],
            r_[6],
            getNftId_,
            setIds_
        );
    }
}

contract ConnectV2FluidVaultT4 is FluidConnector {
    string public constant name = "Fluid-vaultT4-v1.0";
}
