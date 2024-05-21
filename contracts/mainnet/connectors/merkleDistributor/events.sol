//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaim(
        uint256 cumulativeAmount,
        address fToken,
        uint256 cycle,
        bytes32[] merkleProof,
        uint256 rewardsClaimed,
        uint256 setId
    );

    event LogClaimOnBehalf(
        address recipient_,
        uint256 cumulativeAmount,
        address fToken,
        uint256 cycle,
        bytes32[] merkleProof,
        uint256 rewardsClaimed,
        uint256 setId
    );
}
