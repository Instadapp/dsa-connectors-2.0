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

    address internal constant OKX_V6_ROUTER =
        0x2E84246828ddae18500Bc0CF23dd8A8d1Aa5Cf1f;

    address internal constant OKX_V6_TOKEN_SPENDER =
        0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

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

        (bool success, ) = OKX_V6_ROUTER.call{value: wavaxAmt}(
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
                OKX_V6_TOKEN_SPENDER,
                swapData._sellAmt
            );
        }

        swapData._buyAmt = _swapHelper(swapData, avaxAmt);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}
