//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";
import {Basic} from "../../common/basic.sol";

contract EETHContract is Helpers, Basic, Events {
    /**
     * @dev deposit wETH into Etherfi.
     * @notice unwrap wETH and stake ETH in Etherfi, users receive eETH tokens on a 1:1 basis representing their staked ETH.
     * @param amount The amount of ETH to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of ETH deposited.
     */
    function depositWeth(
        uint256 amount,
        uint256 getId,
        uint256 setId
    ) public returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amount = getUint(getId, amount);
        _amount = _amount == type(uint256).max
            ? WETH_CONTRACT.balanceOf(address(this))
            : _amount;

        uint256 _ethBeforeBalance = address(this).balance;

        WETH_CONTRACT.approve(address(WETH_CONTRACT), _amount);
        WETH_CONTRACT.withdraw(_amount);

        uint256 _ethAfterBalance = address(this).balance;

        uint256 _ethAmount = sub(_ethAfterBalance, _ethBeforeBalance);
        ETHERFI_POOL.deposit{value: _ethAmount}();

        setUint(setId, _ethAmount);

        _eventName = "LogDepositWeth(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amount, getId, setId);
    }

    /**
     * @dev deposit ETH into Etherfi.
     * @notice stake ETH in Etherfi, users receive eETH tokens on a 1:1 basis representing their staked ETH.
     * @param amount The amount of ETH to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of ETH deposited.
     */
    function deposit(
        uint256 amount,
        uint256 getId,
        uint256 setId
    )
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amount = getUint(getId, amount);
        _amount = _amount == type(uint256).max
            ? address(this).balance
            : _amount;

        ETHERFI_POOL.deposit{value: _amount}();

        setUint(setId, _amount);

        _eventName = "LogDeposit(uint256,uint256,uint256)";
        _eventParam = abi.encode(_amount, getId, setId);
    }
}

contract ConnectV2EETH is EETHContract {
    string public name = "EETH-v1.0";
}
