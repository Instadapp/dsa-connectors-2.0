//SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

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

    address internal constant OKX_ROUTER =
        0xA748D6573acA135aF68F2635BE60CB80278bd855;

    address internal constant OKX_TOKEN_SPENDER =
        0x3B86917369B83a6892f553609F3c2F439C184e31;

    function _swapHelper(
        SwapData memory swapData,
        uint256 wavaxAmt
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

        (bool success, ) = OKX_ROUTER.call{value: wavaxAmt}(
            swapData.callData
        );
        if (!success) revert("okx-swap-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(
        SwapData memory swapData,
        uint256 setId
    ) internal returns (SwapData memory) {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 avaxAmt;

        if (address(_sellAddr) == avaxAddr) {
            avaxAmt = swapData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                OKX_TOKEN_SPENDER,
                swapData._sellAmt
            );
        }

        swapData._buyAmt = _swapHelper(swapData, avaxAmt);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}
