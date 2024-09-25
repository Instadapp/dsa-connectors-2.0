//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import "./events.sol";
import {Basic} from "../../common/basic.sol";

/**
 * @title USDS Connectos.
 * @dev Upgrade to USDS or Revert to DAI.
 */

contract USDSConnector is Basic, Helpers, Events {
    /**
     * @dev Upgrade DAI into USDS.
     * @notice Convert DAI into USDS.
     * @param daiAmount The amount of DAI to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve DAI amount.
     * @param setId ID stores the amount of USDS.
     */
    function deposit(
        uint256 daiAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _daiAmount = getUint(getId, daiAmount);

        _daiAmount = _daiAmount == type(uint256).max
            ? DAI.balanceOf(address(this))
            : _daiAmount;

        uint256 _usdsBalanceBefore = USDS.balanceOf(address(this));

        approve(DAI, address(DAI_USDS_CONVERTER), _daiAmount);
        DAI_USDS_CONVERTER.daiToUsds(address(this), _daiAmount);

        uint256 _usdsAmount = USDS.balanceOf(address(this)) - _usdsBalanceBefore;

        setUint(setId, _daiAmount);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_daiAmount, _usdsAmount, getId, setId);
    }

    /**
     * @dev Revert USDS into DAI.
     * @notice Convert USDS into DAI.
     * @param usdsAmount The amount of USDS to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve USDS amount.
     * @param setId ID stores the amount of DAI.
     */
    function withdraw(
        uint256 usdsAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _usdsAmount = getUint(getId, usdsAmount);

        _usdsAmount = _usdsAmount == type(uint256).max
            ? USDS.balanceOf(address(this))
            : _usdsAmount;

        uint256 _daiBalanceBefore = DAI.balanceOf(address(this));

        approve(USDS, address(DAI_USDS_CONVERTER), _usdsAmount);
        DAI_USDS_CONVERTER.usdsToDai(address(this), _usdsAmount);

        uint256 _daiAmount = DAI.balanceOf(address(this)) - _daiBalanceBefore;

        setUint(setId, _usdsAmount);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_usdsAmount, _daiAmount, getId, setId);
    }
}

contract ConnectV2USDS is USDSConnector {
    string public constant name = "USDS-v1.0";
}
