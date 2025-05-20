//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title MATICX Connector
 * @dev This is a wrapper for swapMaticForMaticXViaInstantPool method
 */

import {Helpers} from "./helpers.sol";
import {IStaderChildPool} from "./interface.sol";

abstract contract MaticXConnector is Helpers{
    function swapMaticForMaticX() external payable{
        IStaderChildPool pool = IStaderChildPool(STADER_CHILD_POOL);
        pool.swapMaticForMaticXViaInstantPool{value: msg.value}();
    }
}

contract ConnectV2MaticXPolygon is MaticXConnector {
    string public constant name = "MaticX-v1.0";
}
