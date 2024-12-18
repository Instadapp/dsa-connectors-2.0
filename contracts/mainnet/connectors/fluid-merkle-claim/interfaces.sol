//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IFluidMerkleDistributor {
    function claim(
        address recipient_,
        uint256 cumulativeAmount_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_
    ) external;
}

interface IFluidMerkleDistributorV2 {
    function claim(
        address recipient_,
        uint256 cumulativeAmount_,
        uint8 positionType_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        bytes memory metadata_
    ) external;
}
