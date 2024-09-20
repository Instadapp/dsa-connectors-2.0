//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {ISUSDS} from "./interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers {
    /**
     * @dev referral key
     */
    uint16 internal constant referralKey = 0;
   
    /**
     * @dev susds interface
     */
    ISUSDS internal constant susds =
        ISUSDS(0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD);

    /**
     * @dev usds interface
     */
    TokenInterface internal constant usds =
        TokenInterface(0xdC035D45d973E3EC169d2276DDab16f1e407384F);
}
