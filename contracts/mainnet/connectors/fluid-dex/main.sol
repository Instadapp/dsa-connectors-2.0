//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid Dex.
 * @dev Dex.
 */

import {Events} from "./events.sol";
import {IFluidDex} from "./interface.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import {Basic} from "../../common/basic.sol";

abstract contract FluidDex is Basic, Events {
    /**
     * @dev Returns Eth address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Deposits in Fluid Dex
     * @param dex_ Fluid dex address
     * @param token0Amt_ The amount of token0 to deposit
     * @param token1Amt_ The amount of token1 to deposit
     * @param minSharesAmt_ The minimum amount of shares the user expects to receive
     * @param estimate_ If true, function will revert with estimated shares without executing the deposit
     */
    function depositInDex(
        address dex_,
        uint256 token0Amt_,
        uint256 token1Amt_,
        uint256 minSharesAmt_,
        bool estimate_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        IFluidDex.ConstantViews memory constantsView_ = IFluidDex(dex_)
            .constantsView();

        uint256 ethAmt_;
        bool token0IsMax_ = token0Amt_ == type(uint256).max;
        bool token1IsMax_ = token1Amt_ == type(uint256).max;

        if (constantsView_.token0 == getEthAddr()) {
            ethAmt_ = token0IsMax_ ? address(this).balance : token0Amt_;
        } else {
            if (token0IsMax_) {
                token0Amt_ = TokenInterface(constantsView_.token0).balanceOf(
                    address(this)
                );
            }

            approve(TokenInterface(constantsView_.token0), dex_, token0Amt_);
        }

        if (constantsView_.token1 == getEthAddr()) {
            ethAmt_ = token1IsMax_ ? address(this).balance : token1Amt_;
        } else {
            if (token1IsMax_) {
                token1Amt_ = TokenInterface(constantsView_.token1).balanceOf(
                    address(this)
                );
            }

            approve(TokenInterface(constantsView_.token1), dex_, token1Amt_);
        }

        // Deposit in Fluid Dex
        IFluidDex(dex_).deposit{value: ethAmt_}(
            token0Amt_,
            token1Amt_,
            minSharesAmt_,
            true
        );

        _eventName = "LogFluidDexDeposit(address,uint256,uint256,uint256,bool)";
        _eventParam = abi.encode(
            dex_,
            constantsView_.token0,
            constantsView_.token1,
            token0Amt_,
            token1Amt_,
            minSharesAmt_,
            estimate_
        );
    }
}

contract ConnectV2FluidDex is FluidDex {
    string public constant name = "Fluid-dex-v1.0";
}
