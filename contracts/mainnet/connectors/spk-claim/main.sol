//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Helpers} from "./helpers.sol";
import {ISparkRewards} from "./interface.sol";
import {Events} from "./events.sol";

/**
 * @title SPK Claim Connector
 * @dev Contract to handle SPK token airdrop claims.
 */
contract SPKClaimConnector is Helpers, Events {
    /**
     * @param claimType The type of claim to perform. 0 = ignition, 1 = pfl3, 2 = cookie3
     * @param epoch The epoch number to claim.
     * @param account The account to claim for.
     * @param cumulativeAmount The cumulative amount to claim.
     * @param expectedMerkleRoot The expected merkle root.
     * @param merkleProof The merkle proof.
     */
    function claim(
        uint256 claimType,
        uint256 epoch,
        address account,
        uint256 cumulativeAmount,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (claimType == 0) {
            ISparkRewards(IGNITION_REWARDS).claim(
                epoch,
                account,
                SPK_TOKEN,
                cumulativeAmount,
                expectedMerkleRoot,
                merkleProof
            );
        } else if (claimType == 1) {
            ISparkRewards(PFL3_REWARDS).claim(
                epoch,
                account,
                SPK_TOKEN,
                cumulativeAmount,
                expectedMerkleRoot,
                merkleProof
            );
        } else if (claimType == 2) {
            ISparkRewards(COOKIE3_REWARDS).claim(
                epoch,
                account,
                SPK_TOKEN,
                cumulativeAmount,
                expectedMerkleRoot,
                merkleProof
            );
        }

        _eventName = "LogClaim(uint256,address,uint256,bytes32,bytes32[])";
        _eventParam = abi.encode(
            claimType,
            epoch,
            account,
            cumulativeAmount,
            expectedMerkleRoot,
            merkleProof
        );
    }
}

contract ConnectV2SPKClaimConnector is SPKClaimConnector {
    string public constant name = "SPK-Claim-v1.0";
}
