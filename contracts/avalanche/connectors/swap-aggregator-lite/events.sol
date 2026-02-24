// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title Events for Swap Aggregator Lite.
contract Events {
    event LogSwapAggregator(
        string[] connectors,
        string connectorName,
        string eventName,
        bytes eventParam
    );
}
