//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Morpho rewards claim connector.
 */

import {Stores} from "../../common/stores.sol";
import {Events} from "./events.sol";
import {IMorphoDistributor} from "./interfaces.sol";

abstract contract MorphoClaimConnector is Stores, Events {
    /**
     * 
     * @param distributorAddress Rewards distributor address.
     * @param rewardToken  Reward token address.
     * @param claimableAmount  Claimable amount.
     * @param proof  Merkle proof.
     * @param setId  Set claim amount to setId.
     */
    function claim(
        address distributorAddress,
        address rewardToken,
        uint256 claimableAmount,
        bytes32[] calldata proof,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(proof.length > 0, "proofs-empty");

        IMorphoDistributor distributor = IMorphoDistributor(
            distributorAddress
        );

        uint256 claimAmount = distributor.claim(
            address(this),
            rewardToken,
            claimableAmount,
            proof
        );

        setUint(setId, claimAmount);

        _eventName = "LogClaimed(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            distributorAddress,
            rewardToken,
            claimAmount,
            setId
        );
    }
}

contract ConnectV2MorphoClaim is MorphoClaimConnector {
    string public constant name = "Morpho-Claim-v1.0";
}
