// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FluidDexV2Events {
    event LogOperate(
        uint8 positionType,
        uint256 nftId,
        uint256 positionIndex_,
        bytes actionData
    );

    event LogOperateWithIds(
        uint8 positionType,
        uint256 nftId,
        uint256 positionIndex_,
        bytes actionData,
        uint256[] getIds,
        uint256[] setIds
    );
    
    event LogChangeEmode(uint256 nftId, uint256 newEmode);
}
