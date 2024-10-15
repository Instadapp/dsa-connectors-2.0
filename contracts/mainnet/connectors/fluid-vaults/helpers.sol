//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IVaultT4} from "./interface.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers is Basic {
    /**
     * @dev Returns Eth address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function _bothPositive(uint256 a, uint256 b) internal pure returns (bool) {
        return a > 0 && b > 0;
    }

    function _validateIds(
        uint256[] memory getIds_,
        uint256[] memory setIds_
    ) internal pure {
        if (
            _bothPositive(getIds_[1], getIds_[3]) ||
            _bothPositive(getIds_[2], getIds_[4])
        ) {
            revert("Supply and withdraw get IDs cannot both be > 0.");
        }

        if (
            _bothPositive(getIds_[5], getIds_[7]) ||
            _bothPositive(getIds_[6], getIds_[8])
        ) {
            revert("Borrow and payback get IDs cannot both be > 0.");
        }

        if (
            _bothPositive(setIds_[1], setIds_[3]) ||
            _bothPositive(setIds_[2], setIds_[4])
        ) {
            revert("Supply and withdraw set IDs cannot both be > 0.");
        }

        if (
            _bothPositive(setIds_[5], setIds_[7]) ||
            _bothPositive(setIds_[6], setIds_[8])
        ) {
            revert("Borrow and payback set IDs cannot both be > 0.");
        }
    }

    function _adjustTokenValues(
        uint256 idDepositOrBorrow_,
        uint256 idWithdrawOrPayback_,
        int256 colOrDebtAmt_
    ) internal returns (int256) {
        return
            idDepositOrBorrow_ > 0
                ? int256(getUint(idDepositOrBorrow_, uint256(colOrDebtAmt_))) // Token supply or borrow
                : idWithdrawOrPayback_ > 0
                    ? -int256(
                        getUint(idWithdrawOrPayback_, uint256(colOrDebtAmt_))
                    ) // Token withdraw or payback
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
            ethAmt_ = isMax_ ? address(this).balance : uint256(colAmt_);

            colAmt_ = int256(ethAmt_);
        } else {
            if (isMax_) {
                colAmt_ = int256(
                    TokenInterface(token_).balanceOf(address(this))
                );
            }

            approve(TokenInterface(token_), vaultAddress_, uint256(colAmt_));
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
            ethAmt_ = isMin_ ? repayApproveAmt_ : uint256(-debtAmt_);
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

    function _setIds(
        uint256 idSupplyOrBorrow_,
        uint256 idWithdrawOrPayback,
        uint256 tokenAmt_
    ) internal {
        idSupplyOrBorrow_ > 0
            ? setUint(idSupplyOrBorrow_, tokenAmt_)
            : setUint(idWithdrawOrPayback, tokenAmt_);
    }

    function _handleOperatePerfectSetIds(
        int256 tokenActionAmount_,
        uint256 depositOrBorrowId_,
        uint256 withdrawOrPaybackId_
    ) internal {
        if (tokenActionAmount_ > 0) {
            setUint(depositOrBorrowId_, uint256(tokenActionAmount_));
        } else {
            if (tokenActionAmount_ < 0) {
                setUint(withdrawOrPaybackId_, uint256(tokenActionAmount_));
            }
        }
    }
}
