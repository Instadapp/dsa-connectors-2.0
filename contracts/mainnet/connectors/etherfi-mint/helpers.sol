//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IEtherfiVampire} from "./interfaces.sol";

contract Helpers {
    address internal constant REFERRAL_ADDRESS =
        0x0000000000000000000000000000000000000000;

    address internal constant STETH_ADDRESS =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address internal constant EETH_ADDRESS =
        0x35fA164735182de50811E8e2E824cFb9B6118ac2;

    IEtherfiVampire internal constant ETHERFI_VAMPIRE_CONTRACT =
        IEtherfiVampire(0x9FFDF407cDe9a93c47611799DA23924Af3EF764F);
}
