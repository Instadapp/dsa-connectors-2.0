//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interface.sol";

contract AaveMeritClaimConnector {
    function claimAll(
        address distributor,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        address[] memory addressArray = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            addressArray[i] = address(this);
        }

        IMerkleDistributor(distributor).claim(
            addressArray,
            tokens,
            amounts,
            merkleProofs
        );
    }
}

contract ConnctV2AaveMeritClaimAvalanche is AaveMeritClaimConnector {
    string public constant name = "Aave-Merit-Claim-v1.0";
}
