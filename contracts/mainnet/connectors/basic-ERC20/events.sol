//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogApprove(
        address token,
        address spender,
        uint256 amt,
        uint256 getId,
        uint256 setId
    );
}
