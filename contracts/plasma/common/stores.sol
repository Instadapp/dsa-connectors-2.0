//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {MemoryInterface, InstaMapping, ListInterface, InstaConnectors} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return XPL address
     */
    address internal constant xplAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped XPL address
     */
    address internal constant wxplAddr =
        0x6100E367285b01F48D07953803A2d8dCA5D19873;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant instaMemory =
        MemoryInterface(0xA4BF319968986D2352FA1c550D781bBFCCE3FcaB);

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    // @TODO: check!
    InstaMapping internal constant instaMapping =
        InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

    /**
     * @dev Return InstaList Address
     */
    ListInterface internal constant instaList =
        ListInterface(0xA9B99766E6C676Cf1975c0D3166F96C0848fF5ad);

    /**
     * @dev Return connectors registry address
     */
    InstaConnectors internal constant instaConnectors =
        InstaConnectors(0x01fEF4d2B513C9F69E34b2f93Ef707FA9Ff60109);

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
