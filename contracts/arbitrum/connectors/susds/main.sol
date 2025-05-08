//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title SUSDS Connectors.
 * @dev Interface for Spark PSM3 contract for DSA.
 */

import "./helpers.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/basic.sol";

contract SUSDSConnector is Helpers, Basic {
    /**
     * 
     * @param assetInAddr Address of the asset to swap (e.g. USDS, USDC)
     * @param assetOutAddr Address of the asset to swap (e.g. USDS, USDC)
     * @param amountIn Amount of asset to swap in (e.g. USDS, USDC amount)
	 * @param getId ID to retrieve amount.
	 * @param setId ID stores the amount of tokens swapped in.
     */
    function swapExactIn(
        address assetInAddr,
        address assetOutAddr,
        uint256 amountIn,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amountIn = getUint(getId, amountIn);

        _amountIn = _amountIn == type(uint256).max
            ? TokenInterface(assetInAddr).balanceOf(address(this))
            : _amountIn;

        approve(TokenInterface(assetInAddr), address(SparkPSM3), _amountIn);

        uint256 minAmountOut = SparkPSM3.previewSwapExactIn(
            assetInAddr,
            assetOutAddr,
            _amountIn
        );

        SparkPSM3.swapExactIn(
            assetInAddr,
            assetOutAddr,
            _amountIn,
            minAmountOut,
            address(this),
            referralCode
        );

        setUint(setId, _amountIn);

        _eventName = "LogSwapExactIn(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(assetInAddr, assetOutAddr, _amountIn, getId, setId);
    }

    /**
     * 
     * @param assetInAddr Address of the asset to swap (e.g. USDS, USDC)
     * @param assetOutAddr Address of the asset to swap (e.g. USDS, USDC)
     * @param amountOut Amount of asset to swap out (e.g. USDS, USDC amount)
	 * @param getId ID to retrieve amount.
	 * @param setId ID stores the amount of tokens swapped out.
     */
    function swapExactOut(
        address assetInAddr,
        address assetOutAddr,
        uint256 amountOut,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _amountOut = getUint(getId, amountOut);

        uint256 maxAmountIn = SparkPSM3.previewSwapExactOut(
            assetInAddr,
            assetOutAddr,
            _amountOut
        );

        approve(TokenInterface(assetInAddr), address(SparkPSM3), maxAmountIn);

        SparkPSM3.swapExactOut(
            assetInAddr,
            assetOutAddr,
            _amountOut,
            maxAmountIn,
            address(this),
            referralCode
        );

        setUint(setId, _amountOut);

        _eventName = "LogSwapExactOut(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(assetInAddr, assetOutAddr, _amountOut, getId, setId);
    }
}

contract ConnectV2SUSDSArbitrum is SUSDSConnector {
    string public constant name = "SUSD-Arbitrum-v1.1";
}
