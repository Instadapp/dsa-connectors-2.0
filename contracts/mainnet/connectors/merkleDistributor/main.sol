//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";
import {IFluidMerkleDistributor} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract FluidMerkle is Basic, Events {
    IFluidMerkleDistributor internal constant MERKLE_DISTRIBUTOR =
        IFluidMerkleDistributor(address(0));

    TokenInterface internal constant TOKEN =
        TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);

    /**
     * @dev Claims rewards from Fluid merkle distributor contract
     * @param cumulativeAmount_ Total reward cumulated since reward inception.
     * @param fToken_ Address of fToken on which rewards are being distributed.
     * @param cycle_ Current epoch cycle.
     * @param merkleProof_ Merkle proof that validates this claim.
     * @param setId_ Id to set the rewards received.
     */
    function claim(
        uint256 cumulativeAmount_,
        address fToken_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 rewardsBeforeBal_ = TOKEN.balanceOf(address(this));

        MERKLE_DISTRIBUTOR.claim(
            address(this),
            cumulativeAmount_,
            fToken_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = TOKEN.balanceOf(address(this)) -
            rewardsBeforeBal_;

        _eventName = "LogClaim(uint256,address,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
            cumulativeAmount_,
            fToken_,
            cycle_,
            merkleProof_,
            rewardsClaimed_,
            setId_
        );
    }

    /**
     * @dev Claims rewards from Fluid merkle distributor contract
     * @param cumulativeAmount_ Total reward cumulated since reward inception.
     * @param fToken_ Address of fToken on which rewards are being distributed.
     * @param cycle_ Current epoch cycle.
     * @param merkleProof_ Merkle proof that validates this claim.
     * @param setId_ Id to set the rewards received.
     */
    function claimOnBehalf(
        address recipient_,
        uint256 cumulativeAmount_,
        address fToken_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 rewardsBeforeBal_ = TOKEN.balanceOf(recipient_);

        MERKLE_DISTRIBUTOR.claim(
            recipient_,
            cumulativeAmount_,
            fToken_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = TOKEN.balanceOf(recipient_) -
            rewardsBeforeBal_;

        _eventName = "LogClaimOnBehalf(address,uint256,address,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
            recipient_,
            cumulativeAmount_,
            fToken_,
            cycle_,
            merkleProof_,
            rewardsClaimed_,
            setId_
        );
    }
}

contract ConnectV2FluidMerkleClaim is FluidMerkle {
    string public constant name = "Fluid-Merkle-v1.0";
}
