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
        SparkIncentivesInterface(0x4370D3b6C9588E02ce9D22e684387859c7Ff5b34);
}
