//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";

contract SwapAggregatorConnector is Helpers, Events {
    function swap(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        bytes calldata callData,
        address routerAddress,
        address allowanceHolderAddress,
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

        swapData = _swap(swapData, routerAddress, allowanceHolderAddress, setId);

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

contract ConnectV2SwapAggregator is SwapAggregatorConnector {
    string public name = "Insta-Swap-Aggregator-v1.0";
}
