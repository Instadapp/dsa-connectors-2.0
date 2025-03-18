//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interface.sol";

contract Helpers {
    uint256 internal constant referralCode = 1006;

    address internal constant SUSDSAddr =
        0xdDb46999F8891663a8F2828d25298f70416d7610;
        
    ISparkPSM3 internal constant SparkPSM3 =
        ISparkPSM3(0x2B05F8e1cACC6974fD79A673a341Fe1f58d27266);
}
