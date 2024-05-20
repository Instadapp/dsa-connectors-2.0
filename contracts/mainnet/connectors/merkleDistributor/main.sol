//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { IFluidMerkleDistributor } from "./interface.sol";

abstract contract FluidMerkle is Basic, Events {

    address private constant MERKLE_DISTRIBUTOR = address(0);
    
    /**
     * @dev Claims rewards from Fluid merkle distributor contract
     * @param cumulativeAmount_ Total reward cumulated since reward inception.
     * @param fToken_ Address of fToken on which rewards are being distributed.
     * @param cycle_ Current epoch cycle.
     * @param merkleProof_ Merkle proof that validates this claim.
     * @param getId_ Id to get the cumulative amount.
     */
    function claim(
        uint256 cumulativeAmount_,
        address fToken_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 getId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId_, cumulativeAmount_);

        IFluidMerkleDistributor distributorContract_ = IFluidMerkleDistributor(MERKLE_DISTRIBUTOR);

        distributorContract_.claim(address(this), _amt, fToken_, cycle_, merkleProof_);

        _eventName = "LogClaim(uint256,address,uint256,bytes32[],uint256)";
        _eventParam = abi.encode(_amt, fToken_, cycle_, merkleProof_, getId_);
    }

    /**
     * @dev Claims rewards from Fluid merkle distributor contract
     * @param cumulativeAmount_ Total reward cumulated since reward inception.
     * @param fToken_ Address of fToken on which rewards are being distributed.
     * @param cycle_ Current epoch cycle.
     * @param merkleProof_ Merkle proof that validates this claim.
     * @param getId_ Id to get the cumulative amount.
    */
    function claimOnBehalf(
        address recipient_,
        uint256 cumulativeAmount_,
        address fToken_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 getId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId_, cumulativeAmount_);

        IFluidMerkleDistributor distributorContract_ = IFluidMerkleDistributor(MERKLE_DISTRIBUTOR);

        distributorContract_.claim(recipient_, _amt, fToken_, cycle_, merkleProof_);

        _eventName = "LogClaimOnBehalf(address,uint256,address,uint256,bytes32[],uint256)";
        _eventParam = abi.encode(recipient_, _amt, fToken_, cycle_, merkleProof_, getId_);
    }
}

contract ConnectV2FluidMerkleClaim is FluidMerkle {
    string public constant name = "Fluid-Merkle-v1.0";
}