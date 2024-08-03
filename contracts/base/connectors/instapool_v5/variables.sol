//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { InstaFlashV5Interface } from "./interfaces.sol";

contract Variables {

    /**
    * @dev Instapool contract proxy
    */
    InstaFlashV5Interface public constant instaPool =
        InstaFlashV5Interface(0x352423e2fA5D5c99343d371C9e3bC56C87723Cc7);
}