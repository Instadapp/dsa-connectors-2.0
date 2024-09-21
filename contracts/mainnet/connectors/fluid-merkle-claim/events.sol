//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaim(
        address merkleDistributorContract,
        address rewardToken,
        uint256 cumulativeAmount,
        bytes32 positionId,
        uint256 cycle,
        bytes32[] merkleProof,
        uint256 rewardsClaimed,
        uint256 setId
    );

    event LogClaimOnBehalf(
        address merkleDistributorContract,
        address rewardToken,
        address recipient_,
        uint256 cumulativeAmount,
        bytes32 positionId,
        uint256 cycle,
        bytes32[] merkleProof,
        uint256 rewardsClaimed,
        uint256 setId
    );
}
