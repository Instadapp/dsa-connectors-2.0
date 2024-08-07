//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Merkle rewards claiming connector.
*/

import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";
import { IMerkleDistributor } from "./interfaces.sol";

abstract contract MerkleClaimConnector is Stores, Events {
    
    /**
     * @dev Claim Merkle Rewards.
     * @param merkleContract Address on merkle distributor contract.
     * @param index The node index to verify the merkle proof.
     * @param amount The amount of reward to claim.
     * @param setId ID stores the amount of rewards claimed.
    */
    function claim(
        address merkleContract,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(merkleProof.length > 0, "proofs-empty");

        IMerkleDistributor merkleDistribute = IMerkleDistributor(merkleContract);

        merkleDistribute.claim(index, address(this), amount, merkleProof);

        setUint(setId, amount);

        _eventName = "LogMerkleClaimed(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(merkleContract, index, amount, setId);
    }

}

contract ConnectV2MerkleClaim is MerkleClaimConnector {
    string public constant name = "Merkle-claim-v0";
}