//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IDaiUsdsConverter} from "./interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers {
    TokenInterface internal constant DAI =
        TokenInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    
    TokenInterface internal constant USDS =
        TokenInterface(0xdC035D45d973E3EC169d2276DDab16f1e407384F);

    IDaiUsdsConverter internal constant DAI_USDS_CONVERTER =
        IDaiUsdsConverter(0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A);
}
