//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers {
    address internal constant WEETHS =
        0x917ceE801a67f933F2e6b33fC0cD1ED2d5909D88;

    IWEETHSDeposit internal constant WEETHS_DEPOSIT_CONTRACT =
        IWEETHSDeposit(0x99dE9e5a3eC2750a6983C8732E6e795A35e7B861);
}
