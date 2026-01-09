//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";

abstract contract Helpers is Stores, Basic {
    /**
     * @dev dexSimulation Address
     */
    address internal constant dexSimulation =
        0xc3213C00DC33C3F5be91864fbab4Ba3c683aA64B;
}
