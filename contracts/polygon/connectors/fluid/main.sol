//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid.
 * @dev Lending & Borrowing.
 */

import {Stores} from "../../common/stores.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import {Events} from "./events.sol";
import {IVault} from "./interface.sol";

abstract contract FluidConnector is Events, Stores {
    /**
     * @dev Returns Eth address
     */
    function getMaticAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Deposit, borrow, payback and withdraw asset from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol_ New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * For max deposit use type(uint25).max, for max withdraw use type(uint25).min.
     * @param newDebt_ New debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * For max payback use type(uint25).min.
     * @param repayApproveAmt_ In case of max amount for payback, this amount will be approved for spending.
     * Should always be positive.
     * @param getIds_ Array of 5 elements to retrieve IDs:
     * Nft Id, Supply amount, Withdraw amount, Borrow Amount, Payback Amount
     * @param setIds_ Array of 5 elements to store IDs generated:
     * Nft Id, Supply amount, Withdraw amount, Borrow Amount, Payback Amount
     */
    function operate(
        address vaultAddress_,
        uint256 nftId_,
        int256 newCol_,
        int256 newDebt_,
        uint256 repayApproveAmt_,
        uint256[] memory getIds_,
        uint256[] memory setIds_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (getIds_[1] > 0 && getIds_[2] > 0) {
            revert("Supply and withdraw get IDs cannot both be > 0.");
        }

        if (getIds_[3] > 0 && getIds_[4] > 0) {
            revert("Borrow and payback get IDs cannot both be > 0.");
        }

        if (setIds_[1] > 0 && setIds_[2] > 0) {
            revert("Supply and withdraw set IDs cannot both be > 0.");
        }

        if (setIds_[3] > 0 && setIds_[4] > 0) {
            revert("Borrow and payback set IDs cannot both be > 0.");
        }

        nftId_ = getUint(getIds_[0], nftId_);

        newCol_ = getIds_[1] > 0
            ? int256(getUint(getIds_[1], uint256(newCol_)))
            : getIds_[2] > 0
                ? -int256(getUint(getIds_[2], uint256(newCol_)))
                : newCol_;

        newDebt_ = getIds_[3] > 0
            ? int256(getUint(getIds_[3], uint256(newDebt_)))
            : getIds_[4] > 0
                ? -int256(getUint(getIds_[4], uint256(newDebt_)))
                : newDebt_;

        IVault vault_ = IVault(vaultAddress_);

        IVault.ConstantViews memory vaultDetails_ = vault_.constantsView();

        uint256 ethAmount_;

        bool isColMax_ = newCol_ == type(int256).max;

        // Deposit
        if (newCol_ > 0) {
            if (vaultDetails_.supplyToken == getMaticAddr()) {
                ethAmount_ = isColMax_
                    ? address(this).balance
                    : uint256(newCol_);
            } else {
                if (isColMax_) {
                    newCol_ = int256(
                        TokenInterface(vaultDetails_.supplyToken).balanceOf(
                            address(this)
                        )
                    );
                }

                TokenInterface(vaultDetails_.supplyToken).approve(
                    vaultAddress_,
                    uint256(newCol_)
                );
            }
        }

        bool isPaybackMax_ = newDebt_ == type(int256).min;

        // Payback
        if (newDebt_ < 0) {
            if (vaultDetails_.borrowToken == getMaticAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = isPaybackMax_
                    ? repayApproveAmt_
                    : uint256(-1 * newDebt_);
            } else {
                isPaybackMax_
                    ? TokenInterface(vaultDetails_.borrowToken).approve(
                        vaultAddress_,
                        repayApproveAmt_
                    )
                    : TokenInterface(vaultDetails_.borrowToken).approve(
                        vaultAddress_,
                        uint256(-1 * newDebt_)
                    );
            }
        }

        // Note max withdraw will be handled by Fluid contract
        (nftId_, newCol_, newDebt_) = vault_.operate{value: ethAmount_}(
            nftId_,
            newCol_,
            newDebt_,
            address(this)
        );

        setUint(setIds_[0], nftId_);

        setIds_[1] > 0
            ? setUint(setIds_[1], uint256(newCol_))
            : setUint(setIds_[2], uint256(newCol_)); // If setIds_[2] != 0, it will set the ID.
        setIds_[3] > 0
            ? setUint(setIds_[3], uint256(newDebt_))
            : setUint(setIds_[4], uint256(newDebt_)); // If setIds_[4] != 0, it will set the ID.

        _eventName = "LogOperateWithIds(address,uint256,int256,int256,uint256[],uint256[])";
        _eventParam = abi.encode(
            vaultAddress_,
            nftId_,
            newCol_,
            newDebt_,
            getIds_,
            setIds_
        );
    }

    /**
     * @dev Deposit, borrow, payback and withdraw asset from the vault.
     * @notice Single function which handles supply, withdraw, borrow & payback
     * @param vaultAddress_ Vault address.
     * @param nftId_ NFT ID for interaction. If 0 then create new NFT/position.
     * @param newCol_ New collateral. If positive then deposit, if negative then withdraw, if 0 then do nothing.
     * For max deposit use type(uint25).max, for max withdraw use type(uint25).min.
     * @param newDebt_ New debt. If positive then borrow, if negative then payback, if 0 then do nothing
     * For max payback use type(uint25).min.
     * @param repayApproveAmt_ In case of max amount for payback, this amount will be approved for spending.
     * Should always be positive.
     */
    function operate(
        address vaultAddress_,
        uint256 nftId_,
        int256 newCol_,
        int256 newDebt_,
        uint256 repayApproveAmt_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IVault vault_ = IVault(vaultAddress_);

        IVault.ConstantViews memory vaultDetails_ = vault_.constantsView();

        uint256 ethAmount_;

        bool isColMax_ = newCol_ == type(int256).max;

        // Deposit
        if (newCol_ > 0) {
            if (vaultDetails_.supplyToken == getMaticAddr()) {
                ethAmount_ = isColMax_
                    ? address(this).balance
                    : uint256(newCol_);
            } else {
                if (isColMax_) {
                    newCol_ = int256(
                        TokenInterface(vaultDetails_.supplyToken).balanceOf(
                            address(this)
                        )
                    );
                }

                TokenInterface(vaultDetails_.supplyToken).approve(
                    vaultAddress_,
                    uint256(newCol_)
                );
            }
        }

        bool isPaybackMax_ = newDebt_ == type(int256).min;

        // Payback
        if (newDebt_ < 0) {
            if (vaultDetails_.borrowToken == getMaticAddr()) {
                // Needs to be positive as it will be send in msg.value
                ethAmount_ = isPaybackMax_
                    ? repayApproveAmt_
                    : uint256(-1 * newDebt_);
            } else {
                isPaybackMax_
                    ? TokenInterface(vaultDetails_.borrowToken).approve(
                        vaultAddress_,
                        repayApproveAmt_
                    )
                    : TokenInterface(vaultDetails_.borrowToken).approve(
                        vaultAddress_,
                        uint256(-1 * newDebt_)
                    );
            }
        }

        // Note max withdraw will be handled by Fluid contract
        (nftId_, newCol_, newDebt_) = vault_.operate{value: ethAmount_}(
            nftId_,
            newCol_,
            newDebt_,
            address(this)
        );

        _eventName = "LogOperate(address,uint256,int256,int256)";
        _eventParam = abi.encode(
            vaultAddress_,
            nftId_,
            newCol_,
            newDebt_
        );
    }
}

contract ConnectV2FluidPolygon is FluidConnector {
    string public constant name = "Fluid-v1.0";
}
