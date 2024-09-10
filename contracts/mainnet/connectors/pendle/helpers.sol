//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";

abstract contract Helpers is Basic {
    address internal constant PENDLE_ROUTER =
        0x888888888889758F76e7103c6CbF23ABbF58F946;

    struct SwapData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint256 _sellAmt;
        uint256 _buyAmt;
        uint256 unitAmt;
        bytes callData;
    }

    function _swap(
        SwapData memory swapData,
        uint256 setId
    ) internal returns (SwapData memory) {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 ethAmt;

        if (address(_sellAddr) == ethAddr) {
            ethAmt = swapData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                PENDLE_ROUTER,
                swapData._sellAmt
            );
        }

        swapData._buyAmt = _swapHelper(swapData, ethAmt);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }

    function _swapHelper(
        SwapData memory swapData,
        uint256 ethAmt
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

        (bool success, ) = PENDLE_ROUTER.call{value: ethAmt}(swapData.callData);
        if (!success) revert("pendle-swap-failed");

        buyAmt = getTokenBal(buyToken) - initalBal;

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}
