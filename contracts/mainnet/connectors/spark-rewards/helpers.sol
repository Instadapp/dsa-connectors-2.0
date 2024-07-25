//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {SparkIncentivesInterface} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev Spark Incentives
     */
    SparkIncentivesInterface internal constant SPARK_INCENTIVES =
        SparkIncentivesInterface(0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb);
}
