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
                        getUint(idWithdrawOrPayback_, uint256(-colOrDebtAmt_))
                    ) // Token withdraw or payback
                    : colOrDebtAmt_;
    }

    struct HandleDepositData {
        bool isEth;
        bool isMax;
        address vaultAddress;
        address token;
        int256 colAmt;
    }

    function _handleDeposit(
        HandleDepositData memory depositData_
    ) internal returns (uint256 ethAmt_, int256) {
        if (depositData_.isEth) {
            ethAmt_ = depositData_.isMax
                ? address(this).balance
                : uint256(depositData_.colAmt);

            depositData_.colAmt = int256(ethAmt_);
        } else {
            if (depositData_.isMax) {
                depositData_.colAmt = int256(
                    TokenInterface(depositData_.token).balanceOf(address(this))
                );
            }

            approve(
                TokenInterface(depositData_.token),
                depositData_.vaultAddress,
                uint256(depositData_.colAmt)
            );
        }

        return (ethAmt_, depositData_.colAmt);
    }

    struct HandlePaybackData {
        bool isEth;
        bool isMin;
        address token;
        uint256 repayApproveAmt;
        int256 debtAmt;
        address vaultAddress;
    }

    function _handlePayback(
        HandlePaybackData memory paybackData_
    ) internal returns (uint256 ethAmt_) {
        if (paybackData_.isEth) {
            ethAmt_ = paybackData_.isMin
                ? paybackData_.repayApproveAmt
                : uint256(-paybackData_.debtAmt);
        } else {
            paybackData_.isMin
                ? approve(
                    TokenInterface(paybackData_.token),
                    paybackData_.vaultAddress,
                    paybackData_.repayApproveAmt
                )
                : approve(
                    TokenInterface(paybackData_.token),
                    paybackData_.vaultAddress,
                    uint256(-paybackData_.debtAmt)
                );
        }
    }

    function _setIds(
        uint256 idSupplyOrBorrow_,
        uint256 idWithdrawOrPayback,
        int256 tokenAmt_
    ) internal {
        idSupplyOrBorrow_ > 0
            ? setUint(idSupplyOrBorrow_, uint256(tokenAmt_))
            : setUint(idWithdrawOrPayback, uint256(-tokenAmt_));
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
                setUint(withdrawOrPaybackId_, uint256(-tokenActionAmount_));
            }
        }
    }
}
