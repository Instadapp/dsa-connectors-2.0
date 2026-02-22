// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Basic} from "../../common/basic.sol";

abstract contract InstaMemoryUtilsConnector is Basic {

    /**
     * @dev Add uints from getIds and set the sum to the setId in the memory.
     * @param getIds_ Array of getIds.
     * @param setId_ SetId to store the sum.
     */
    function addGetIds(
        uint256[] memory getIds_,
        uint256 setId_
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 sum_;
        for (uint256 i = 0; i < getIds_.length; i++) {
            sum_ += getUint(getIds_[i], 0);
        }

        setUint(setId_, sum_);
        _eventName = "LogAddGetIds(uint256[],uint256)";
        _eventParam = abi.encode(getIds_, sum_);
    }
}

contract ConnectV2InstaMemoryUtilsPolygon is InstaMemoryUtilsConnector {
    string public constant name = "Insta-MemoryUtils-v1.0";
}
