//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./events.sol";
import { Basic } from "../../common/basic.sol";
import { IFluidMerkleDistributor } from "./interfaces.sol";
import { TokenInterface } from "../../common/interfaces.sol";

abstract contract FluidMerkleClaim is Basic, Events {

    IFluidMerkleDistributor internal constant MERKLE_DISTRIBUTOR = 
        IFluidMerkleDistributor(0x0c20EC658abA203c55665D8Dcb4e18304a08ebbd);

    TokenInterface internal constant TOKEN =
        TokenInterface(0x912CE59144191C1204E64559FE8253a0e49E6548);

    function claim(
        uint256 cumulativeAmount_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 rewardsBeforeBal_ = TOKEN.balanceOf(address(this));

        MERKLE_DISTRIBUTOR.claim(
            address(this),
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = TOKEN.balanceOf(address(this)) - rewardsBeforeBal_;
        setUint(setId_, rewardsClaimed_);

        _eventName = "LogClaim(uint256,bytes32,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_,
            rewardsClaimed_,
            setId_
        );
    }

    function claimOnBehalf(
        address recipient_,
        uint256 cumulativeAmount_,
        bytes32 positionId_,
        uint256 cycle_,
        bytes32[] calldata merkleProof_,
        uint256 setId_
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 rewardsBeforeBal_ = TOKEN.balanceOf(address(this));

        MERKLE_DISTRIBUTOR.claim(
            recipient_,
            cumulativeAmount_,
            positionId_,
            cycle_,
            merkleProof_
        );

        uint256 rewardsClaimed_ = TOKEN.balanceOf(address(this)) - rewardsBeforeBal_;
        setUint(setId_, rewardsClaimed_);

        _eventName = "LogClaimOnBehalf(address,uint256,bytes32,uint256,bytes32[],uint256,uint256)";
        _eventParam = abi.encode(
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

contract ConnectV2FluidMerkleClaimArbitrum is FluidMerkleClaim {
    string public constant name = "Fluid-Merkle-v1.0";
}
