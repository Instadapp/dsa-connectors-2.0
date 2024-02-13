//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { InstaFlashV5Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV5Interface public constant instaPool =
        InstaFlashV5Interface(0xAB50Dd1C57938218627Df2311ef65b4e2e84aF48);

}