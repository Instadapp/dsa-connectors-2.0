//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaim(
        uint256 epoch,
        address account,
        uint256 cumulativeAmount,
        bytes32 expectedMerkleRoot,
        bytes32[] merkleProof
    );
}
