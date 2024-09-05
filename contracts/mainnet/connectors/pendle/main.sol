//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenInterface} from "../../common/interfaces.sol";
import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";
import {IPendle} from "./interfaces.sol";

abstract contract Pendle is Basic, Events {
    IPendle constant PENDLE_ROUTER =
        IPendle(0x888888888889758F76e7103c6CbF23ABbF58F946);

    address internal constant STETH_ADDR =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address internal constant WSTETH_ADDR =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address internal constant PENDLESWAP_ADDR =
        0x1e8b6Ac39f8A33f46a6Eb2D1aCD1047B99180AD1;

    /**
     * @dev Swap tokens for Pendle PT.
     * @param market The address of the market to deposit in.
     * @param netTokenIn The amount of tokens to deposit. Use type(uint256).max for entire balance.
     * @param swapData Additional data required for the swap.
     * @param guessPtOut Estimated amount of PT to receive, used for slippage control.
     * @param minPtOut Min amount of PT to receive after swap.
     * @param setId ID stores the amount of PT received.
     */
    function deposit(
        address market,
        uint256 netTokenIn,
        IPendle.SwapData calldata swapData,
        IPendle.ApproxParams calldata guessPtOut,
        uint256 minPtOut,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        TokenInterface wsteth = TokenInterface(WSTETH_ADDR);

        // Use entire balance if netTokenIn is set to max uint256
        netTokenIn = netTokenIn == type(uint256).max
            ? wsteth.balanceOf(address(this))
            : netTokenIn;

        IPendle.TokenInput memory input = IPendle.TokenInput({
            tokenIn: WSTETH_ADDR,
            netTokenIn: netTokenIn,
            tokenMintSy: WSTETH_ADDR,
            pendleSwap: PENDLESWAP_ADDR,
            swapData: swapData
        });

        // Approve PENDLE_ROUTER to spend wstETH
        approve(wsteth, address(PENDLE_ROUTER), input.netTokenIn);

        IPendle.LimitOrderData memory limit = IPendle.LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new IPendle.FillOrderParams[](0),
            flashFills: new IPendle.FillOrderParams[](0),
            optData: "0x"
        });

        (uint256 netPtOut, , ) = PENDLE_ROUTER.swapExactTokenForPt(
            address(this),
            market,
            minPtOut,
            guessPtOut,
            input,
            limit
        );

        // Store the amount of PT received
        setUint(setId, netPtOut);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(market, netTokenIn, minPtOut, setId);
    }

    /**
     * @dev Swap PT for underlying tokens.
     * @param market The address of the market to withdraw from.
     * @param minTokenOut Minimum amount of tokens to receive after swap.
     * @param exactPtIn Exact amount of PT to send for swap.
     * @param setId ID stores the amount of tokens received.
     */
    function withdraw(
        address market,
        uint256 exactPtIn,
        uint256 minTokenOut,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IPendle.TokenOutput memory output = IPendle.TokenOutput({
            tokenOut: WSTETH_ADDR,
            minTokenOut: minTokenOut,
            tokenRedeemSy: WSTETH_ADDR,
            pendleSwap: address(0),
            swapData: IPendle.SwapData({
                swapType: IPendle.SwapType.NONE,
                extRouter: address(0),
                extCalldata: "0x",
                needScale: false
            })
        });

        IPendle.LimitOrderData memory limit = IPendle.LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new IPendle.FillOrderParams[](0),
            flashFills: new IPendle.FillOrderParams[](0),
            optData: "0x"
        });

        // Get initial wstETH balance
        TokenInterface wsteth = TokenInterface(WSTETH_ADDR);
        uint256 initialBal = wsteth.balanceOf(address(this));

        PENDLE_ROUTER.swapExactPtForToken(
            address(this),
            market,
            exactPtIn,
            output,
            limit
        );

        // Calculate the amount of wstETH received from the swap
        uint256 swapAmtReceived = wsteth.balanceOf(address(this)) - initialBal;

        // Store the amount of wstETH received
        setUint(setId, swapAmtReceived);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(market, exactPtIn, minTokenOut, setId);
    }
}

contract ConnectV2Pendle is Pendle {
    string public constant name = "Pendle-v1.0";
}
