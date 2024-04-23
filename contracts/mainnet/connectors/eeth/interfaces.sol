//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IEtherfiPool {
    function deposit() external payable returns (uint256);
}
