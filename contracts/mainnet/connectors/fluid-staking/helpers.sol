//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IStakingRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
  TokenInterface constant internal REWARD_TOKEN =
    TokenInterface(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb); // TODO: Update
}