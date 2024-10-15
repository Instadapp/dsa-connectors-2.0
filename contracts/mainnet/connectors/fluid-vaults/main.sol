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
        if ((getIds_[1] > 0 && getIds_[3] > 0) || (getIds_[2] > 0 && getIds_[4] > 0)) {
            revert("Supply and withdraw get IDs cannot both be > 0.");
        }

        if ((getIds_[5] > 0 && getIds_[7] > 0) || (getIds_[6] > 0 && getIds_[8] > 0)) {
            revert("Borrow and payback get IDs cannot both be > 0.");
        }

        if ((setIds_[1] > 0 && setIds_[3] > 0) || (setIds_[2] > 0 && setIds_[4] > 0)) {
            revert("Supply and withdraw set IDs cannot both be > 0.");
        }

        if ((setIds_[5] > 0 && setIds_[7] > 0) || (setIds_[6] > 0 && setIds_[8] > 0)) {
            revert("Borrow and payback set IDs cannot both be > 0.");
        }

        nftId_ = getUint(getIds_[0], nftId_);

        newColToken0_ = getIds_[1] > 0
            ? int256(getUint(getIds_[1], uint256(newColToken0_))) // Token 0 supply
            : getIds_[3] > 0 
                ? -int256(getUint(getIds_[3], uint256(newColToken0_))) // Token 0 withdraw
                : newColToken0_;

        newColToken1_ = getIds_[2] > 0
            ? int256(getUint(getIds_[2], uint256(newColToken1_))) // Token 1 supply
            : getIds_[4] > 0 
                ? -int256(getUint(getIds_[4], uint256(newColToken1_))) // Token 1 withdraw
                : newColToken1_;

        newDebtToken0_ = getIds_[5] > 0
            ? int256(getUint(getIds_[5], uint256(newDebtToken0_)))
            : getIds_[7] > 0
                ? -int256(getUint(getIds_[7], uint256(newDebtToken0_)))
                : newDebtToken0_;

        newDebtToken1_ = getIds_[6] > 0
            ? int256(getUint(getIds_[6], uint256(newDebtToken1_)))
            : getIds_[8] > 0
                ? -int256(getUint(getIds_[8], uint256(newDebtToken1_)))
                : newDebtToken1_;

        
        IVaultT4 vaultT4_ = IVaultT4(vaultAddress_);

        IVaultT4.ConstantViews memory vaultT4Details_ = vaultT4_.constantsView();

        uint256 ethAmount_;

        bool isCol0Max_ = newColToken0_ == type(int256).max;
        bool isCol1Max_ = newColToken1_ == type(int256).max;

        // Deposit token 0
        if (newColToken0_ > 0) {
            if (vaultT4Details_.supplyToken.token0 == getEthAddr()) {
                ethAmount_ = isCol0Max_
                    ? address(this).balance
                    : uint256(newColToken0_);

                newColToken0_ = int256(ethAmount_);
            } else {
                if (isCol0Max_) {
                    newColToken0_ = int256(
                        TokenInterface(vaultT4Details_.supplyToken.token0).balanceOf(
                            address(this)
                        )
                    );
                }

                approve(
                    TokenInterface(vaultT4Details_.supplyToken.token0), 
                    vaultAddress_, 
                    uint256(newColToken0_)
                );
            }
        }

        // Deposit token 1
        if (newColToken1_ > 0) {
            if (vaultT4Details_.supplyToken.token1 == getEthAddr()) {
                ethAmount_ = isCol1Max_
                    ? address(this).balance
                    : uint256(newColToken1_);

                newColToken1_ = int256(ethAmount_);
            } else {
                if (isCol1Max_) {
                    newColToken1_ = int256(
                        TokenInterface(vaultT4Details_.supplyToken.token1).balanceOf(
                            address(this)
                        )
                    );
                }

                approve(
                    TokenInterface(vaultT4Details_.supplyToken.token1), 
                    vaultAddress_, 
                    uint256(newColToken1_)
                );
            }
        }

        bool isPayback0Min_ = newDebtToken0_ == type(int256).min;
        bool isPayback1Min_ = newDebtToken1_ == type(int256).min;

        // Payback token 0
        if (isPayback0Min_ < 0) {
            if (vaultT4Details_.borrowToken.token0 == getEthAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = isPayback0Min_
                    ? repayApproveAmtToken0_
                    : uint256(-newDebtToken0_);
            } else {
                isPayback0Min_
                    ? approve(
                        TokenInterface(vaultT4Details_.borrowToken.token0), 
                        vaultAddress_, 
                        repayApproveAmtToken0_
                    )
                    : approve(
                        TokenInterface(vaultT4Details_.borrowToken.token0), 
                        vaultAddress_, 
                        uint256(-newDebtToken0_)
                    );
            }
        }

        // Payback token 1
        if (isPayback1Min_ < 0) {
            if (vaultT4Details_.borrowToken.token1 == getEthAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = isPayback1Min_
                    ? repayApproveAmtToken1_
                    : uint256(-newDebtToken1_);
            } else {
                isPayback1Min_
                    ? approve(
                        TokenInterface(vaultT4Details_.borrowToken.token1), 
                        vaultAddress_, 
                        repayApproveAmtToken1_
                    )
                    : approve(
                        TokenInterface(vaultT4Details_.borrowToken.token1), 
                        vaultAddress_, 
                        uint256(-newDebtToken1_)
                    );
            }
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

        setIds_[1] > 0
            ? setUint(setIds_[1], uint256(newColToken0_))
            : setUint(setIds_[3], uint256(newColToken0_)); // If setIds_[2] != 0, it will set the ID.
        setIds_[2] > 0
            ? setUint(setIds_[2], uint256(newColToken1_))
            : setUint(setIds_[4], uint256(newColToken1_)); // If setIds_[4] != 0, it will set the ID.
        setIds_[5] > 0
            ? setUint(setIds_[5], uint256(newDebtToken0_))
            : setUint(setIds_[7], uint256(newDebtToken0_)); // If setIds_[4] != 0, it will set the ID.
        setIds_[6] > 0
            ? setUint(setIds_[6], uint256(newDebtToken1_))
            : setUint(setIds_[8], uint256(newDebtToken1_)); // If setIds_[4] != 0, it will set the ID.

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
}

contract ConnectV2FluidVaultT4 is FluidConnector {
    string public constant name = "Fluid-vaultT4-v1.0";
}
