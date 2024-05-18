//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
}

struct RewardOwed {
    address token;
    uint256 owed;
}

interface CometInterface {
    function supply(address asset, uint256 amount) external;

    function supplyTo(address dst, address asset, uint256 amount) external;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function transferAsset(address dst, address asset, uint256 amount) external;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint256 amount
    ) external;

    function withdraw(address asset, uint256 amount) external;

    function withdrawTo(address to, address asset, uint256 amount) external;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint256 amount
    ) external;

    function approveThis(
        address manager,
        address asset,
        uint256 amount
    ) external;

    function withdrawReserves(address to, uint256 amount) external;

    function absorb(address absorber, address[] calldata accounts) external;

    function buyCollateral(
        address asset,
        uint256 minAmount,
        uint256 baseAmount,
        address recipient
    ) external;

    function quoteCollateral(
        address asset,
        uint256 baseAmount
    ) external view returns (uint256);

    function userCollateral(
        address,
        address
    ) external returns (UserCollateral memory);

    function baseToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function borrowBalanceOf(address account) external view returns (uint256);

    function allow(address manager, bool isAllowed_) external;

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed_,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
