//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMerkleDistributor {
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proof
    ) external;
}
