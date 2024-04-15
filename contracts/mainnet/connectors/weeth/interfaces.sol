//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWEETH{
    function balanceOf(address account) external view returns (uint256);
    function wrap(uint256 _eETHAmount) external returns (uint256);
    function unwrap(uint256 _weETHAmount) external returns (uint256);
}