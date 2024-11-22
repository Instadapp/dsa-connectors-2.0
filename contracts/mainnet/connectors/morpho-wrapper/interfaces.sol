//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMorphoWrapper {
    function depositFor(address account, uint256 value) external returns (bool);
}
