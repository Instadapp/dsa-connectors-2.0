//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface VTokenInterface {
    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function underlying() external view returns (address);
}

interface NativeVTokenInterface {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable returns (uint256);

    function repayBorrowBehalf(address borrower)
        external
        payable
        returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata vTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);
}
