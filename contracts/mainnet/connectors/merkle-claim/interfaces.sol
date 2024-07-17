//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMerkleDistributor {
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}