//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
    event LogClaimAll(
        address distributor,
        address[] tokens,
        uint256[] amounts,
        bytes32[][] merkleProofs
    );
}
