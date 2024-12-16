//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interface.sol";

contract Helpers {
    uint256 internal constant referralCode = 1006;

    address internal constant SUSDSAddr =
        0x5875eEE11Cf8398102FdAd704C9E96607675467a;
        
    ISparkPSM3 internal SparkPSM3 =
        ISparkPSM3(0x1601843c5E9bC251A3272907010AFa41Fa18347E);
}
