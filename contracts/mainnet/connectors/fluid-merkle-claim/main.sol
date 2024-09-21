//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./events.sol";
import { Basic } from "../../common/basic.sol";
import { IFluidMerkleDistributor } from "./interfaces.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract FluidMerkleClaim is Basic, Events {
    function claim(
        address merkleDistributorContract,
        address rewardToken,
        uint256 cumulativeAmount_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenInterface REWARD_TOKEN = TokenInterface(rewardToken);
        IFluidMerkleDistributor MERKLE_DISTRIBUTOR = IFluidMerkleDistributor(merkleDistributorContract);

        uint256 rewardsBeforeBal_ = REWARD_TOKEN.balanceOf(address(this));
        MERKLE_DISTRIBUTOR.claim(
            address(this),
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = REWARD_TOKEN.balanceOf(address(this)) - rewardsBeforeBal_;
        setUint(setId_, rewardsClaimed_);

        _eventName = "LogClaim(address,address,uint256,bytes32,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
            merkleDistributorContract,
            rewardToken,
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_,
            rewardsClaimed_,
            setId_
        );
    }

    function claimOnBehalf(
        address merkleDistributorContract,
        address rewardToken,
        address recipient_,
        uint256 cumulativeAmount_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        TokenInterface REWARD_TOKEN = TokenInterface(rewardToken);
        IFluidMerkleDistributor MERKLE_DISTRIBUTOR = IFluidMerkleDistributor(merkleDistributorContract);

        uint256 rewardsBeforeBal_ = REWARD_TOKEN.balanceOf(address(this));
        MERKLE_DISTRIBUTOR.claim(
            recipient_,
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = REWARD_TOKEN.balanceOf(address(this)) - rewardsBeforeBal_;
        setUint(setId_, rewardsClaimed_);

        _eventName = "LogClaimOnBehalf(address,address,uint256,bytes32,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
            merkleDistributorContract,
            rewardToken,
            recipient_,
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_,
            rewardsClaimed_,
            setId_
        );
    }
}

contract ConnectV2FluidMerkleClaim is FluidMerkleClaim {
    string public constant name = "Fluid-Merkle-v1.0";
}
