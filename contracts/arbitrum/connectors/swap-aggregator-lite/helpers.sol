// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {InstaConnectors} from "../../common/interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract SwapHelpers {
    struct SwapAmounts {
        uint256 sellAmount;
        uint256 buyAmount;
    }

    struct SwapResult {
        bool success;
        bytes returnData;
        string connector;
    }

    /// @dev Instadapp Connectors Registry.
    InstaConnectors internal constant INSTA_CONNECTORS =
        InstaConnectors(0x67fCE99Dd6d8d659eea2a1ac1b8881c57eb6592B);

    /**
     * @dev Swap using the dex aggregators. Tries each connector in order and
     *      returns on the first successful execution.
     * @param connectors_ Connector names in preference order.
     * @param datas_ Encoded calldata for each connector.
     */
    function _swap(
        string[] memory connectors_,
        bytes[] memory datas_
    )
        internal
        returns (SwapResult memory swapResult_)
    {
        uint256 length_ = connectors_.length;
        require(length_ > 0, "zero-length-not-allowed");
        require(datas_.length == length_, "calldata-length-invalid");

        (bool isOk, address[] memory connectorAddresses_) = INSTA_CONNECTORS.isConnectors(
            connectors_
        );
        require(isOk, "connector-names-invalid");

        for (uint256 i = 0; i < length_; i++) {
            (swapResult_.success, swapResult_.returnData) = connectorAddresses_[i].delegatecall(datas_[i]);
            if (swapResult_.success) {
                swapResult_.connector = connectors_[i];
                break;
            }
        }
    }

    /**
     * @dev Returns the USD value of `amount_` in 1e18 decimals.
     * @param tokenAddress_ Token address (used to read its decimals).
     * @param amount_ Token amount in its native decimals.
     * @param exchangeRate_ Token price in USD, scaled to 1e18.
     * @return amountInUsd_ USD value scaled to 1e18.
     */
    function _getAmountInUsd(
        address tokenAddress_,
        uint256 amount_,
        uint256 exchangeRate_
    ) internal view returns (uint256 amountInUsd_) {
        uint256 tokenDecimals_ = TokenInterface(tokenAddress_).decimals();
        amountInUsd_ =
            (amount_ * exchangeRate_) /
            (10 ** tokenDecimals_);
    }
}
