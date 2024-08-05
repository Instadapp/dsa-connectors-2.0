//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {  CometRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	CometRewards internal constant cometRewards =
		CometRewards(0x443EA0340cb75a160F31A440722dec7b5bc3C2E9);
}
