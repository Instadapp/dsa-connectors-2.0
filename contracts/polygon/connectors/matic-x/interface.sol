//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IStaderChildPool {
    function swapMaticForMaticXViaInstantPool() external payable;

    function convertMaticToMaticX(
        uint256 _balance
    ) external view returns (uint256, uint256, uint256);
}
