//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interface.sol";
import "./events.sol";

contract AaveMeritClaimConnector is Events {
    function claimAll(
        address distributor,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external returns (string memory _eventName, bytes memory _eventParam) {
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

        _eventName = "LogClaimAll(address,address[],uint256[],bytes32[][])";
        _eventParam = abi.encode(distributor, tokens, amounts, merkleProofs);
    }
}

contract ConnctV2AaveMeritClaim is AaveMeritClaimConnector {
    string public constant name = "Aave-Merit-Claim-v1.0";
}
