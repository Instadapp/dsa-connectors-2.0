//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMakerPsm {
    function buyGem(address, uint256) external payable;
}
