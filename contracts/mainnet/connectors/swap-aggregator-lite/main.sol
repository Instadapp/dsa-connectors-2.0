// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Swap Aggregator for Lite Vaults.
 * @dev Swap integration for DEX Aggregators.
 * @dev Connector Name: SWAP-AGGREGATOR-B
 */

import {SwapHelpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract SwapAggregatorLite is SwapHelpers, Events {
    /**
     * @dev Swap the tokens using the connectors.
     * @param sellTokenAddr_ address of the sell token.
     * @param buyTokenAddr_ address of the buy token.
     * @param minBuyAmount_ minimum buy amount.
     * @param sellTokenExchangePrice_ exchange rate of the sell token.
     * @param buyTokenExchangePrice_ exchange rate of the buy token.
     * @param maxSwapLossPercentage_ maximum swap loss percentage in basis points.
     * @param connectors_ name of the connectors in preference order.
     * @param datas_ data for the swap cast.
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
        // Initialize sell amount with current balance of sellToken
        uint256 sellAmount_ = TokenInterface(sellTokenAddr_).balanceOf(
            address(this)
        );

        // Initialize buy amount with current balance of buyToken
        uint256 buyAmount_ = TokenInterface(buyTokenAddr_).balanceOf(
            address(this)
        );

        (
            bool success,
            bytes memory returnData,
            string memory connector
        ) = _swap(connectors_, datas_);

        require(success, "swap-Aggregator-failed");
        (string memory eventName, bytes memory eventParam) = abi.decode(
            returnData,
            (string, bytes)
        );

        // Calculate the swapped amounts
        sellAmount_ =
            sellAmount_ -
            TokenInterface(sellTokenAddr_).balanceOf(address(this));
        buyAmount_ =
            buyAmount_ -
            TokenInterface(buyTokenAddr_).balanceOf(address(this));

        // maxSwapLossPercentage_ check
        require(
            _getAmountInUsd(sellTokenAddr_, sellAmount_, sellTokenExchangePrice_) <
            (_getAmountInUsd(buyTokenAddr_, buyAmount_, buyTokenExchangePrice_) * (1e4 + maxSwapLossPercentage_)) /1e4,
            "loss-greater-than-max-swap-loss-percentage"
        );

        // minBuyAmount_ check
        require( minBuyAmount_ < buyAmount_, "amount-received-less");

        eventName_ = "LogSwapAggregator(string[],string,string,bytes)";
        eventParam_ = abi.encode(connectors_, connector, eventName, eventParam);
    }
}

contract ConnectV2SwapAggregatorLite is SwapAggregatorLite {
    string public name = "Swap-Aggregator-Lite-v1.0";
}
