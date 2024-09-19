//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IDaiUsdsConverter {
    function daiToUsds(address usr, uint256 wad) external;
    function usdsToDai(address usr, uint256 wad) external;
}