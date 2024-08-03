//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {MemoryInterface, InstaMapping, ListInterface, InstaConnectors} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant instaMemory =
        MemoryInterface(0xc109f7Ef06152c3a63dc7254fD861E612d3Ac571);

    /**
     * @dev Return InstaList Address
     */
    ListInterface internal constant instaList =
        ListInterface(0x3565F6057b7fFE36984779A507fC87b31EFb0f09);

    /**
     * @dev Return connectors registry address
     */
    InstaConnectors internal constant instaConnectors =
        InstaConnectors(0x67fCE99Dd6d8d659eea2a1ac1b8881c57eb6592B);

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
