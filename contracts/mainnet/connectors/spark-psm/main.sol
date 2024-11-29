//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import "./events.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/basic.sol";
import {ISparkPsm} from "./interface.sol";

/**
 * @title Spark PSM Connector.
 * @dev Connector to interact with Spark PSM to convert DAI to USDC in 1:1 Ratio.
 */

contract SparkPSMConnector is Basic, Helpers, Events {
    /**
     * @dev Buy Gem from Spark PSM.
     * @param amt Amount of DAI.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID from `InstaMemory` Contract.
     */
    function swapDaiToUsdc(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 amt_ = getUint(getId, amt);

        uint256 usdcBalanceBefore_ = TokenInterface(USDC_ADDRESS).balanceOf(
            address(this)
        );

        approve(TokenInterface(DAI_ADDRESS), SPARK_PSM_ADDRESS, amt_);

        ISparkPsm(SPARK_PSM_ADDRESS).buyGem(address(this), convert18ToDec(6, amt_));

        uint256 usdcBalanceAfter_ = TokenInterface(USDC_ADDRESS).balanceOf(
            address(this)
        );

        uint256 usdcAmt_ = usdcBalanceAfter_ - usdcBalanceBefore_;
        setUint(setId, usdcAmt_);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(amt_, getId, setId);
    }
}

contract ConnectV2SparkPSM is SparkPSMConnector {
    string public constant name = "Spark-PSM-v1.0";
}
