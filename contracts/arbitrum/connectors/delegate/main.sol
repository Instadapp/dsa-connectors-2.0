//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interface.sol";
import "./events.sol";

contract DelegateConnector is Events {
    function delegate(
        address token,
        address delegatee
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        IVoteToken(token).delegate(delegatee);

        _eventName = "LogDelegate(address,address)";
        _eventParam = abi.encode(token, delegatee);
    }
}

contract ConnectV2DelegateArbitrum is DelegateConnector {
    string public constant name = "Delegate-v1.1";
}
