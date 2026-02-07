//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InstaFlashV5Interface} from "./interfaces.sol";

contract Variables {
    /**
     * @dev Instapool contract proxy
     */
    InstaFlashV5Interface public constant instaPool =
        InstaFlashV5Interface(0xe620726686B480d955E63b9c7c1f93c2f8c1aCf4);
}
