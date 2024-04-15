//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers{
    IWEETH internal constant WEETH_CONTRACT = IWEETH(0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee);
    TokenInterface internal constant EETH_CONTRACT = TokenInterface(0x35fA164735182de50811E8e2E824cFb9B6118ac2);
}
