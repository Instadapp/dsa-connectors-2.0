//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {Basic} from "../../common/basic.sol";

contract SUSDSConnector is Basic, Helpers, Events {
     /**
     * @dev Deposit USDS into sUSDS.
     * @notice Deposit USDS into sUSDS (Saving USDS).
     * @param usdsAmount The amount of USDS to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve USDS amount.
     * @param setId ID stores the amount of sUSDS.
     */
    function deposit(
        uint256 usdsAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _usdsAmount = getUint(getId, usdsAmount);
        _usdsAmount = _usdsAmount == type(uint).max
            ? usds.balanceOf(address(this))
            : _usdsAmount;

        // TODO: Obtain referral code
        usds.approve(address(susds), _usdsAmount);
        uint256 _susdsAmount = susds.deposit(_usdsAmount, address(this), 0); // this returns shares

        setUint(setId, _susdsAmount);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_usdsAmount, _susdsAmount, getId, setId);
    }

    /**
     * @dev Withdraw sUSDS into USDS.
     * @notice Withdraw sUSDS into USDS (Saving USDS).
     * @param susdsAmount The amount of USDS to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve sUSDS amount.
     * @param setId ID stores the amount of USDS.
     */
    function withdraw(
        uint256 susdsAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _susdsAmount = getUint(getId, susdsAmount);
        _susdsAmount = _susdsAmount == type(uint).max
            ? susds.balanceOf(address(this))
            : _susdsAmount;

        susds.approve(address(susds), _susdsAmount);
        uint256 _usdsAmount = susds.withdraw(
            _susdsAmount,
            address(this),
            address(this)
        ); // this returns shares

        setUint(setId, _usdsAmount);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_susdsAmount, _usdsAmount, getId, setId);
    }
}

contract ConnectV2SUSDS is SUSDSConnector {
    string public constant name = "SUSDS-v1.0";
}
