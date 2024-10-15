//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid.
 * @dev Lending & Borrowing.
 */

import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

import {Events} from "./events.sol";
import {IVaultT4} from "./interface.sol";

abstract contract FluidConnector is Events, Basic {
    /**
     * @dev Returns Eth address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function _bothPositive(uint256 a, uint256 b) internal pure returns (bool) {
        return a > 0 && b > 0;
    }

    function _validateIds(uint256[] memory getIds_, uint256[] memory setIds_) internal pure {
        if (_bothPositive(getIds_[1], getIds_[3]) || _bothPositive(getIds_[2], getIds_[4])) {
            revert("Supply and withdraw get IDs cannot both be > 0.");
        }

        if (_bothPositive(getIds_[5], getIds_[7]) || _bothPositive(getIds_[6], getIds_[8])) {
            revert("Borrow and payback get IDs cannot both be > 0.");
        }

        if (_bothPositive(setIds_[1], setIds_[3]) || _bothPositive(setIds_[2], setIds_[4])) {
            revert("Supply and withdraw set IDs cannot both be > 0.");
        }

        if (_bothPositive(setIds_[5], setIds_[7]) || _bothPositive(setIds_[6], setIds_[8])) {
            revert("Borrow and payback set IDs cannot both be > 0.");
        }
    }

    function _adjustTokenValues(
        uint256 idDepositOrBorrow_,
        uint256 idWithdrawOrPayback_,
        int256 colOrDebtAmt_
    ) internal returns (int256) {
        return idDepositOrBorrow_ > 0
            ? int256(getUint(idDepositOrBorrow_, uint256(colOrDebtAmt_))) // Token supply or borrow
            : idWithdrawOrPayback_ > 0 
                ? -int256(getUint(idWithdrawOrPayback_, uint256(colOrDebtAmt_))) // Token withdraw or payback
                : colOrDebtAmt_;
    }

    function _handleDeposit(
        bool isEth_,
        bool isMax_,
        address vaultAddress_,
        address token_,
        int256 colAmt_
    ) internal returns (uint256 ethAmt_, int256) {

        if (isEth_) {
            ethAmt_ = isMax_
                ? address(this).balance
                : uint256(colAmt_);

            colAmt_ = int256(ethAmt_);
        } else {
            if (isMax_) {
                colAmt_ = int256(
                    TokenInterface(token_).balanceOf(address(this))
                );
            }

            approve(
                TokenInterface(token_), 
                vaultAddress_, 
                uint256(colAmt_)
            );
        }

        return (ethAmt_, colAmt_);
    }

    function _handlePayback(
        bool isEth_,
        bool isMin_,
        address token_,
        uint256 repayApproveAmt_,
        int256 debtAmt_,
        address vaultAddress_
    ) internal returns (uint256 ethAmt_) {
        if (isEth_) {
            ethAmt_ = isMin_
                ? repayApproveAmt_
                : uint256(-debtAmt_);
        } else {
            isMin_
                ? approve(
                    TokenInterface(token_), 
                    vaultAddress_, 
                    repayApproveAmt_
                )
                : approve(
                    TokenInterface(token_), 
                    vaultAddress_, 
                    uint256(-debtAmt_)
                );
        }
    }

    function _setIds(uint256 idSupplyOrBorrow_, uint256 idWithdrawOrPayback, uint256 tokenAmt_) internal {
        idSupplyOrBorrow_ > 0
            ? setUint(idSupplyOrBorrow_, tokenAmt_)
            : setUint(idWithdrawOrPayback, tokenAmt_);
    }

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

    // /**
    //  * @dev Deposit, borrow, payback and withdraw asset from the vault.
    //  * @notice Single function which handles supply, withdraw, borrow & payback
    //  * @param vaultAddress_ Vault address.
    //  * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
    //  * @param newCol_ New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
    //  * For max deposit use type(uint25).max, for max withdraw use type(uint25).min.
    //  * @param newDebt_ New debt. If positive then borrow, if negative then payback, if 0 then do nothing
    //  * For max payback use type(uint25).min.
    //  * @param repayApproveAmt_ In case of max amount for payback, this amount will be approved for spending.
    //  * Should always be positive.
    //  * @param getIds_ Array of 9 elements to retrieve IDs:
    //  * Nft Id
    //  * Supply amount token 0
    //  * Supply amount token 1
    //  * Withdraw amount token 0
    //  * Withdraw amount token 1
    //  * Borrow amount token 0
    //  * Borrow amount token 1
    //  * Payback amount token 0
    //  * Payback amount token 1
    //  */






    // 0 - nft id
    // 1 - final col shares amount
    ///              2 - token0 deposit or withdraw amount
    ///              3 - token1 deposit or withdraw amount
    ///              4 - final debt shares amount
    ///              5 - token0 borrow or payback amount
    ///              6 - token1 borrow or payback amount
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
            if (vaultT4Details_.supplyToken.token0 == getEthAddr()) {
                ethAmount_ = uint256(colToken0MinMax_); // max amount to deposit
            } else {
                approve(
                    TokenInterface(vaultT4Details_.supplyToken.token0), 
                    vaultAddress_, 
                    uint256(colToken0MinMax_)  // max amount to deposit
                );
            }

            if (vaultT4Details_.supplyToken.token1 == getEthAddr()) {
                ethAmount_ = uint256(colToken1MinMax_); // max amount to deposit
            } else {
                approve(
                    TokenInterface(vaultT4Details_.supplyToken.token1), 
                    vaultAddress_, 
                    uint256(colToken1MinMax_)  // max amount to deposit
                );
            }
        }

        // Payback
        if (perfectDebtShares_ < 0) {
            if (vaultT4Details_.borrowToken.token0 == getEthAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = uint256(-debtToken0MinMax_); // max amount to payback
            } else {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token0), 
                    vaultAddress_, 
                    uint256(-debtToken0MinMax_) // max amount to payback
                );
            }

            if (vaultT4Details_.borrowToken.token1 == getEthAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = uint256(-debtToken1MinMax_); // max amount to payback
            } else {
                approve(
                    TokenInterface(vaultT4Details_.borrowToken.token1), 
                    vaultAddress_, 
                    uint256(-debtToken1MinMax_) // max amount to payback
                );
            }
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
    }  
}

contract ConnectV2FluidVaultT4 is FluidConnector {
    string public constant name = "Fluid-vaultT4-v1.0";
}
