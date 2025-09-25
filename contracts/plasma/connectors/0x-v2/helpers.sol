//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract Helpers is DSMath, Basic {
    struct SwapData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

    address internal constant ZEROX_ALLOWANCE_HOLDER =
        0x0000000000001fF3684f28c67538d4D072C22734;

    function _swapHelper(
        SwapData memory swapData,
        uint256 xplAmt
    ) internal returns (uint256 buyAmt) {
        TokenInterface buyToken = swapData.buyToken;
        (uint256 _buyDec, uint256 _sellDec) = getTokensDec(
            buyToken,
            swapData.sellToken
        );
        uint256 _sellAmt18 = convertTo18(_sellDec, swapData._sellAmt);
        uint256 _slippageAmt = convert18ToDec(
            _buyDec,
            wmul(swapData.unitAmt, _sellAmt18)
        );

        uint256 initalBal = getTokenBal(buyToken);

        (bool success, ) = ZEROX_ALLOWANCE_HOLDER.call{value: xplAmt}(
            swapData.callData
        );
        if (!success) revert("odos-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(
        SwapData memory swapData,
        uint256 setId
    ) internal returns (SwapData memory) {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 xplAmount;

        if (address(_sellAddr) == xplAddr) {
            xplAmount = swapData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                ZEROX_ALLOWANCE_HOLDER,
                swapData._sellAmt
            );
        }

        swapData._buyAmt = _swapHelper(swapData, xplAmount);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}
