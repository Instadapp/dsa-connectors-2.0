//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaimed(
        address merkleContract,
        uint256 index,
        uint256 amount,
        uint256 setId
    );
}
