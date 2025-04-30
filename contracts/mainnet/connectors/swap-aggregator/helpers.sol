//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

    function _swapHelper(
        SwapData memory swapData,
        address routerAddress,
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

        (bool success, ) = routerAddress.call{value: ethAmt}(swapData.callData);

        if (!success) revert("swap-execution-failed");

        uint256 finalBal = getTokenBal(buyToken);

        buyAmt = sub(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    function _swap(
        SwapData memory swapData,
        address routerAddress,
        address allowanceHolderAddress,
        uint256 setId
    ) internal returns (SwapData memory) {
        TokenInterface _sellAddr = swapData.sellToken;

        uint256 ethAmount;

        if (address(_sellAddr) == ethAddr) {
            ethAmount = swapData._sellAmt;
        } else {
            approve(
                TokenInterface(_sellAddr),
                allowanceHolderAddress,
                swapData._sellAmt
            );
        }

        swapData._buyAmt = _swapHelper(swapData, routerAddress, ethAmount);

        setUint(setId, swapData._buyAmt);

        return swapData;
    }
}
