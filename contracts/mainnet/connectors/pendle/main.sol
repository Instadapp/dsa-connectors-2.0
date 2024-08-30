//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TokenInterface} from "../../common/interfaces.sol";
import {Basic} from "../../common/basic.sol";
import {Events} from "./events.sol";
import {IPendle} from "./interfaces.sol";

abstract contract Pendle is Basic, Events {
    IPendle constant PENDLE_ROUTER =
        IPendle(0x888888888889758F76e7103c6CbF23ABbF58F946);

    /**
	 * @dev Swap tokens for Pendle PT.
	 * @param market The address of the market to deposit in.
	 * @param minPtOut Min amount of PT to receive after swap.
     * @param guessPtOut The amount of the token to deposit.
	 * @param input Input token data. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)(For max: `uint256(-1)`)
     * @param limit Limit order data.
	 * @param setId ID stores the amount of PT received.
	 */
    function deposit(
        address market,
        uint256 minPtOut,
        IPendle.ApproxParams calldata guessPtOut,
        IPendle.TokenInput memory input,
        IPendle.LimitOrderData calldata limit,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 ethAmt;

        if (input.tokenIn == ethAddr) {
            ethAmt = input.netTokenIn == type(uint256).max ? address(this).balance : input.netTokenIn;
            input.tokenIn = address(0);
        } else {
            TokenInterface token = TokenInterface(input.tokenIn);

            input.netTokenIn = input.netTokenIn == type(uint256).max 
                ? token.balanceOf(address(this)) 
                : input.netTokenIn;

            approve(
                token,
                address(PENDLE_ROUTER),
                input.netTokenIn
            );
        }

        (uint256 netPtOut, , ) = PENDLE_ROUTER.swapExactTokenForPt{value: ethAmt}(
            address(this), 
            market, 
            minPtOut, 
            guessPtOut, 
            input, 
            limit
        );

        setUint(setId, netPtOut);

        _eventName = "LogDeposit(address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(market,minPtOut,input.tokenIn,input.netTokenIn,setId);
    }

    /**
	 * @dev Swap PT for underlying tokens.
	 * @param market The address of the market to withdraw from.
	 * @param exactPtIn Exact amount of PT to send for swap.
	 * @param output Output token data. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)(For max: `uint256(-1)`)
     * @param limit Limit order data.
	 * @param setId ID stores the amount of tokens received.
	 */
    function withdraw(
        address market,
        uint256 exactPtIn,
        IPendle.TokenOutput memory output,
        IPendle.LimitOrderData calldata limit,
        uint256 setId
    ) external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
        uint256 initialBal;
        uint256 finalBal;
        bool isEth = (output.tokenOut == ethAddr);

        if (isEth) {
            initialBal = address(this).balance;
            output.tokenOut = address(0);
        } else {
            TokenInterface tokenContract = TokenInterface(output.tokenOut);
            initialBal = tokenContract.balanceOf(address(this));
        }

        PENDLE_ROUTER.swapExactPtForToken(
            address(this),
            market,
            exactPtIn,
            output,
            limit
        );

        finalBal = isEth 
            ? address(this).balance 
            : TokenInterface(output.tokenOut).balanceOf(address(this));

        uint256 swapAmtReceived = finalBal - initialBal;

        setUint(setId, swapAmtReceived);

        _eventName = "LogWithdraw(address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(market,exactPtIn,output.tokenOut,output.minTokenOut,setId);        
    }
}

contract ConnectV2Pendle is Pendle {
    string public constant name = "Pendle-v1.0";
}
