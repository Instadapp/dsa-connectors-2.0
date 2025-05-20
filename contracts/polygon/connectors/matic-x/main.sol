//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title MATICX Connector
 * @dev This is a wrapper for swapMaticForMaticXViaInstantPool method
 */

import {Helpers} from "./helpers.sol";
import {IStaderChildPool} from "./interface.sol";
import {Stores} from "../../common/stores.sol";
import {Events} from "./events.sol";

abstract contract MaticXConnector is Helpers, Stores, Events {
    function swapMaticForMaticX(
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IStaderChildPool pool = IStaderChildPool(STADER_CHILD_POOL);
        (uint256 _amountInMaticX, , ) = pool.convertMaticToMaticX(msg.value);
        pool.swapMaticForMaticXViaInstantPool{value: msg.value}();

        setUint(setId, _amountInMaticX);

        _eventName = "LogSwapMaticToMaticX(uint256,uint256)";
        _eventParam = abi.encode(msg.value, _amountInMaticX);
    }
}

contract ConnectV2MaticXPolygon is MaticXConnector {
    string public constant name = "MaticX-v1.0";
}
