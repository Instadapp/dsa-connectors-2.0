//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import "./events.sol";
import {Stores} from "../../common/stores.sol";
import {TokenInterface} from "../../common/basic.sol";
import {IMakerPsm} from "./interface.sol";

/**
 * @title Maker PSM Connector.
 * @dev Connector to interact with Maker PSM to convert DAI to USDC in 1:1 Ratio.
 */

contract MakerPsmConnector is Stores, Helpers, Events {
    /**
     * @dev Buy Gem from Maker PSM.
     * @param amt Amount of USDC.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID from `InstaMemory` Contract.
     */
    function deposit(
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amt);

        uint256 usdcBalanceBefore = TokenInterface(usdcAddr).balanceOf(
            address(this)
        );
        IMakerPsm(MakerPsmAddr).buyGem(address(this), _amt);
        uint256 usdcBalanceAfter = TokenInterface(usdcAddr).balanceOf(
            address(this)
        );

        uint256 _usdcAmt = usdcBalanceAfter - usdcBalanceBefore;
        setUint(setId, _usdcAmt);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amt, getId, setId);
    }
}

contract ConnectV2MakerPsm is MakerPsmConnector {
    string public constant name = "Maker-PSM-v1.0";
}
