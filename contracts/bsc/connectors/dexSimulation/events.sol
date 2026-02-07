//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogSimulateSwap(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    );
}
