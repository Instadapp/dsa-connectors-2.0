//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers {
    IEtherfiPool internal constant ETHERFI_POOL =
        IEtherfiPool(0x308861A430be4cce5502d0A12724771Fc6DaF216);
    TokenInterface internal constant WETH_CONTRACT =
        TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
}
