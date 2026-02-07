// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogSwapAggregator(
        string[] connectors,
        string connectorName,
        string eventName,
        bytes eventParam
    );
}
