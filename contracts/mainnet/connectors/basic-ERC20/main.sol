//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Basic, TokenInterface} from "../../common/basic.sol";
import {Events} from "./events.sol";

/**
 * @title Basic-E.
 * @dev Approve ERC20 Connector.
 */

contract BasicERC20Connector is Events, Basic {
    /**
     * @dev Approve ERC20 token.
     * @notice Approve ERC20 token to a spender.
     * @param token The address of the token to approve.
     * @param spender The address of the spender.
     * @param amt The amount to approve.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */
    function approve(
        address token,
        address spender,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amt = getUint(getId, amt);
        approve(TokenInterface(token), spender, _amt);
        setUint(setId, _amt);

        _eventName = "LogApprove(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, spender, _amt, getId, setId);
    }
}

contract ConnectV2BasicERC20 is BasicERC20Connector {
    string public constant name = "Basic-ERC20-Approve-v1.0";
}
