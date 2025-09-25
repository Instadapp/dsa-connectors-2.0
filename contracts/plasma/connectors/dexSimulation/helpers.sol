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
        0xAa48Cca7DCe006F37DBb2e2Ef2dE7ACD5f6F5Dfc;
}
