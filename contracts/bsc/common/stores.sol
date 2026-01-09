//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {MemoryInterface, InstaMapping, ListInterface, InstaConnectors} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return BNB address
     */
    address internal constant bnbAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped BNB address
     */
    address internal constant wbnbAddr =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant instaMemory =
        MemoryInterface(0x68206e807c44216B606493e4415Dc78e0dB25a18);

    /**
     * @dev Return InstaList Address
     */
    ListInterface internal constant instaList =
        ListInterface(0x6fe05374924830B6aC98849f75A3D5766E51Ef10);

    /**
     * @dev Return connectors registry address
     */
    InstaConnectors internal constant instaConnectors =
        InstaConnectors(0xC867edb3d3337529e176b87Fc29Bf84268D28cb5);

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
