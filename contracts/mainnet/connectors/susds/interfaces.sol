//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISUSDS {
    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function deposit(
        uint256 assets,
        address receiver,
        uint16 referral
    ) external returns (uint256 shares);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
}
