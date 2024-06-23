//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Events {
    event LogSwap(
        address buyToken,
        address sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 setId
    );
}