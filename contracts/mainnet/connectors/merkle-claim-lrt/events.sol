//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaimed(
        address merkleContract,
        uint256 amount,
        bytes32 expectedMerkleRoot,
        uint256 setId
    );
}
