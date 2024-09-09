//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./helpers.sol";
import "./events.sol";

contract OKXConnector is Helpers, Events {
    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        Helpers.SwapData memory swapData = Helpers.SwapData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        swapData = _swap(swapData, setId);

        _eventName = "LogSwap(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            address(swapData.buyToken),
            address(swapData.sellToken),
            swapData._buyAmt,
            swapData._sellAmt,
            setId
        );
    }
}

contract ConnectV2OKXBase is OKXConnector {
    string public constant name = "OKX-v1";
}
