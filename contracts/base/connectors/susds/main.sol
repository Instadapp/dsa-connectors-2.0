//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/basic.sol";

contract SUSDSConnector is Helpers, Basic {
    function swapExactIn(
        address assetAddr,
        uint256 amountIn,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amountIn = getUint(getId, amountIn);

        approve(TokenInterface(assetAddr), address(SparkPSM3), _amountIn);

        uint256 minAmountOut = SparkPSM3.previewSwapExactIn(
            assetAddr,
            SUSDSAddr,
            _amountIn
        );

        SparkPSM3.swapExactIn(
            assetAddr,
            SUSDSAddr,
            _amountIn,
            minAmountOut,
            address(this),
            referralCode
        );

        setUint(setId, _amountIn);

        _eventName = "LogSwapExactIn(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(assetAddr, SUSDSAddr, _amountIn, getId);
    }

    function swapExactOut(
        address assetAddr,
        uint256 amountOut,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amountOut = getUint(getId, amountOut);

        uint256 maxAmountIn = SparkPSM3.previewSwapExactOut(
            assetAddr,
            SUSDSAddr,
            _amountOut
        );

        approve(TokenInterface(SUSDSAddr), address(SparkPSM3), maxAmountIn);

        SparkPSM3.swapExactOut(
            SUSDSAddr,
            assetAddr,
            _amountOut,
            maxAmountIn,
            address(this),
            referralCode
        );
        
        setUint(setId, _amountOut);

        _eventName = "LogSwapExactOut(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(assetAddr, SUSDSAddr, _amountOut, getId);
    }
}

contract ConnectV2SUSDSBase is SUSDSConnector {
    string public constant name = "SUSD-Base-v1.0";
}
