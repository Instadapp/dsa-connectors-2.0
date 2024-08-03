//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {MemoryInterface, InstaMapping, ListInterface, InstaConnectors} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return avax address
     */
    address internal constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped AVAX address
     */
    address internal constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant instaMemory =
        MemoryInterface(0x3254Ce8f5b1c82431B8f21Df01918342215825C2);

    /**
     * @dev Return InstaList address
     */
    ListInterface internal constant instaList =
        ListInterface(0x9926955e0Dd681Dc303370C52f4Ad0a4dd061687);

    /**
     * @dev Return connectors registry address
     */
    InstaConnectors internal constant instaConnectors =
        InstaConnectors(0x127d8cD0E2b2E0366D522DeA53A787bfE9002C14);

    /**
     * @dev Get Uint value from InstaMemory Contract.
     */
    function getUint(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : instaMemory.getUint(getId);
    }

    /**
     * @dev Set Uint value in InstaMemory Contract.
     */
    function setUint(uint setId, uint val) internal virtual {
        if (setId != 0) instaMemory.setUint(setId, val);
    }
}
