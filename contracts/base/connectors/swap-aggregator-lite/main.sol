// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Swap Aggregator for Lite Vaults.
 * @dev Swap integration for DEX Aggregators.
 */

import {SwapHelpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract SwapAggregatorLite is SwapHelpers, Events {
    /**
     * @dev Swap tokens via the first successful connector and enforce loss limits.
     * @param sellTokenAddr_ Address of the token being sold.
     * @param buyTokenAddr_ Address of the token being bought.
     * @param minBuyAmount_ Minimum acceptable buy-token amount (in buy-token decimals).
     * @param sellTokenExchangePrice_ Sell-token price in USD, scaled to 1e18.
     * @param buyTokenExchangePrice_ Buy-token price in USD, scaled to 1e18.
     * @param maxSwapLossPercentage_ Maximum allowed swap-loss percentage where 1e6 = 100%.
     * @param connectors_ Connector names in preference order.
     * @param datas_ Encoded calldata for each connector.
     */
    function swap(
        address sellTokenAddr_,
        address buyTokenAddr_,
        uint256 minBuyAmount_,
        uint256 sellTokenExchangePrice_,
        uint256 buyTokenExchangePrice_,
        uint256 maxSwapLossPercentage_,
        string[] memory connectors_,
        bytes[] memory datas_
    )
        external
        payable
        returns (string memory eventName_, bytes memory eventParam_)
    {
        SwapAmounts memory swapAmounts_ = SwapAmounts({
            sellAmount: TokenInterface(sellTokenAddr_).balanceOf(address(this)),
            buyAmount: TokenInterface(buyTokenAddr_).balanceOf(address(this))
        });

        SwapResult memory swapResult_ = _swap(connectors_, datas_);
        require(swapResult_.success, "swap-Aggregator-failed");
        (string memory eventName, bytes memory eventParam) = abi.decode(
            swapResult_.returnData,
            (string, bytes)
        );

        swapAmounts_.sellAmount =
            swapAmounts_.sellAmount - TokenInterface(sellTokenAddr_).balanceOf(address(this));
        swapAmounts_.buyAmount =
            TokenInterface(buyTokenAddr_).balanceOf(address(this)) - swapAmounts_.buyAmount;

        // Ensure USD value sold does not exceed bought value beyond the allowed loss tolerance.
        require(
            _getAmountInUsd(sellTokenAddr_, swapAmounts_.sellAmount, sellTokenExchangePrice_) <
            (_getAmountInUsd(buyTokenAddr_, swapAmounts_.buyAmount, buyTokenExchangePrice_) * (1e6 + maxSwapLossPercentage_)) / 1e6,
            "loss-greater-than-max-swap-loss-percentage"
        );

        require(minBuyAmount_ < swapAmounts_.buyAmount, "amount-received-less");

        eventName_ = "LogSwapAggregator(string[],string,string,bytes)";
        eventParam_ = abi.encode(connectors_, swapResult_.connector, eventName, eventParam);
    }
}

contract ConnectV2SwapAggregatorLite is SwapAggregatorLite {
    string public name = "Swap-Aggregator-Lite-v1.0";
}
