//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenInterface} from "../../common/interfaces.sol";

interface IMakerManager {
    function cdpAllow(uint cdp, address usr, uint ok) external;
    function cdpCan(address, uint, address) external view returns (uint);
    function ilks(uint) external view returns (bytes32);
    function last(address) external view returns (uint);
    function count(address) external view returns (uint);
    function owns(uint) external view returns (address);
    function urns(uint) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint);
    function give(uint, address) external;
    function frob(uint, int, int) external;
    function flux(uint, address, uint) external;
    function move(uint, address, uint) external;
}

interface IFluidWalletFactory {
    function computeWallet(address owner_) external view returns (address);
}
