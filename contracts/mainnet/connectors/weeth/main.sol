//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";
import {Basic} from "../../common/basic.sol";

contract WEETHContract is Helpers, Basic, Events {

    /**
     * @dev Deposit eETH into weETH.
     * @notice Wrap eETH into weETH
     * @param eETHAmount The amount of eETH to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve eETH amount.
     * @param setId ID stores the amount of weETH deposited.
     */
    function deposit(
        uint256 eETHAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _eETHAmount = getUint(getId, eETHAmount);
        _eETHAmount = _eETHAmount == type(uint256).max
            ? eETHContract.balanceOf(address(this))
            : _eETHAmount;

        approve(eETHContract, address(weETHContract), _eETHAmount);
        uint256 _weETHAmount = weETHContract.wrap(_eETHAmount);

        setUint(setId, _weETHAmount);

        _eventName = "LogDeposit(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_eETHAmount, _weETHAmount, getId, setId);
    }

    /**
     * @dev Withdraw eETH from weETH from Smart Account
     * @notice Unwrap eETH from weETH
     * @param weETHAmount The amount of weETH to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve weETH amount.
     * @param setId ID stores the amount of eETH.
     */
    function withdraw(
        uint256 weETHAmount,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _weETHAmount = getUint(getId, weETHAmount);
        _weETHAmount = _weETHAmount == type(uint256).max
            ? weETHContract.balanceOf(address(this))
            : _weETHAmount;

        uint256 _eETHAmount = weETHContract.unwrap(_weETHAmount);
        setUint(setId, _eETHAmount);

        _eventName = "LogWithdraw(uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_weETHAmount, _eETHAmount, getId, setId);
    }
}

contract ConnectV2WEETH is WEETHContract {
    string public constant name = "WEETH-v1.0";
}
