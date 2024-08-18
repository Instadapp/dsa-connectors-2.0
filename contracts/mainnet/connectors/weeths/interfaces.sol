//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface IWEETHSDeposit {
    function deposit(
        ERC20 depositAsset,
        uint256 depositAmount,
        uint256 minimumMint
    ) external payable returns (uint256 shares);
}
