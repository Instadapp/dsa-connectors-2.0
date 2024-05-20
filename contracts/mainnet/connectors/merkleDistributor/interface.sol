//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFluidMerkleDistributor {
    function claim(
        address recipient_,
        uint256 cumulativeAmount_,
        address fToken_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_
    ) external;
}