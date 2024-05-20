// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Events {
    event LogTransferToFluid(uint256 indexed vault, bytes32 indexed ilk, address indexed fluidAddress);
}