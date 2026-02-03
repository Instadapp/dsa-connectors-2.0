// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IFluidDexV2} from "./interfaces.sol";
import {FluidDexV2Events} from "./events.sol";
import {FluidDexV2Helpers} from "./helpers.sol";
import {Basic} from "../../common/basic.sol";
import {OperateWithIdsVariables, PositionParams} from "./interfaces.sol";

contract FluidDexV2MMConnector is FluidDexV2Events, Basic, FluidDexV2Helpers {
    /// @notice Operate
    /// @dev This function is used to operate
    /// @param positionType_ The type of position to operate
    /// @param nftId_ The ID of the NFT to operate
    /// @param positionIndex_ The index of the position to operate
    /// @param actionData_ The data to operate
    /// @return _eventName The name of the event
    /// @return _eventParam The parameters of the event
    function operate(
        uint8 positionType_,
        uint256 nftId_,
        uint256 positionIndex_,
        bytes calldata actionData_
    )
        external
        payable
        validatePositionType(positionType_)
        returns (string memory _eventName, bytes memory _eventParam)
    {
        // @TODO: Handle Token Approvals - Find a way to find tokenAddress from tokenIndex or maybe pass tokenAddress as param
        // @TODO: Handle max cases (as for max cases actionData_ amount is maxInt/minInt)

        IFluidDexV2(FLUID_DEX_V2_MM_ADDRESS).operate(
            nftId_,
            positionIndex_,
            actionData_
        );

        _eventName = "LogOperate(uint8,uint256,uint256,bytes)";
        _eventParam = abi.encode(
            positionType_,
            nftId_,
            positionIndex_,
            actionData_
        );
    }

    /// @notice Operate with IDs
    /// @dev This function is used to operate with IDs
    /// @param positionType_ The type of position to operate
    /// @param nftId_ The ID of the NFT to operate
    /// @param positionIndex_ The index of the position to operate
    /// @param actionData_ The data to operate
    /// @param getIds_ The IDs to get - [nftId_, positionIndex_, operateCollateralAmount0, operateCollateralAmount1, operateDebtAmount0, operateDebtAmount1]
    /// @param setIds_ The IDs to set - [nftId_, positionIndex_, operateCollateralAmount0, operateCollateralAmount1, operateDebtAmount0, operateDebtAmount1]
    /// @return _eventName The name of the event
    /// @return _eventParam The parameters of the event
    function operateWithIds(
        uint8 positionType_,
        uint256 nftId_,
        uint256 positionIndex_,
        bytes memory actionData_,
        uint256[] memory getIds_,
        uint256[] memory setIds_
    )
        external
        payable
        validatePositionType(positionType_)
        returns (string memory _eventName, bytes memory _eventParam)
    {
        OperateWithIdsVariables memory operateWithIdsVariables_;

        // nftId_
        nftId_ = getUint(getIds_[0], nftId_);
        // positionIndex_
        positionIndex_ = getUint(getIds_[1], positionIndex_);

        // @TODO: Handle Token Approvals - Find a way to find tokenAddress from tokenIndex or maybe pass tokenAddress as param
        // @TODO: Handle max cases (as for max cases actionData_ amount is maxInt/minInt)

        if (positionType_ == 1) {
            if (_isNewPosition(nftId_)) {
                // Handle only supply amount
                uint256 tokenIndex;
                (, tokenIndex, operateWithIdsVariables_.operateCollateralAmount0) = abi.decode(actionData_, (uint256, uint256, uint256));
                operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], operateWithIdsVariables_.operateCollateralAmount0);
                actionData_ = abi.encode(1, tokenIndex, operateWithIdsVariables_.operateCollateralAmount0);
            } else {
                (int256 amountInt, ) = abi.decode(actionData_, (int256, address));
                if (amountInt >= 0) {
                    // Handle Supply Amount
                    operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], uint256(amountInt));
                    actionData_ = abi.encode(int256(operateWithIdsVariables_.operateCollateralAmount0), address(0));
                } else {
                    // Handle Withdraw Amount
                    operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], uint256(-amountInt));
                    actionData_ = abi.encode(-int256(operateWithIdsVariables_.operateCollateralAmount0), address(this));
                }
            }
        } else if (positionType_ == 2) {
            if (_isNewPosition(nftId_)) {
                // Handle only borrow amount
                uint256 tokenIndex;
                (, tokenIndex, operateWithIdsVariables_.operateDebtAmount0) = abi.decode(actionData_, (uint256, uint256, uint256));
                operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], operateWithIdsVariables_.operateDebtAmount0);
                actionData_ = abi.encode(2, tokenIndex, operateWithIdsVariables_.operateDebtAmount0, address(this));
            } else {
                (int256 amountInt, ) = abi.decode(actionData_, (int256, address));
                if (amountInt >= 0) {
                    // Handle borrow amount
                    operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], uint256(amountInt));
                    actionData_ = abi.encode(int256(operateWithIdsVariables_.operateDebtAmount0), address(this));
                } else {
                    // Handle payback amount
                    operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], uint256(-amountInt));
                    actionData_ = abi.encode(-int256(operateWithIdsVariables_.operateDebtAmount0), address(this));
                }
            }
        } else if (positionType_ == 3) {
            if (_isNewPosition(nftId_)) {
                (, PositionParams memory positionParams_) = abi.decode(actionData_, (uint256, PositionParams));
                operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], positionParams_.amount0);
                operateWithIdsVariables_.operateCollateralAmount1 = getUint(getIds_[3], positionParams_.amount1);

                positionParams_.amount0 = operateWithIdsVariables_.operateCollateralAmount0;
                positionParams_.amount1 = operateWithIdsVariables_.operateCollateralAmount1;
                positionParams_.to = address(this);
                actionData_ = abi.encode(3, positionParams_);
            } else {
                (int256 amount0Int, int256 amount1Int, , , ) = abi.decode(actionData_, (int256, int256, uint256, uint256, address));
                if (amount0Int >= 0) {
                    // Handle supply amount for token0
                    operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], uint256(amount0Int));
                    amount0Int = int256(operateWithIdsVariables_.operateCollateralAmount0);
                } else {
                    // Handle withdraw amount for token0
                    operateWithIdsVariables_.operateCollateralAmount0 = getUint(getIds_[2], uint256(-amount0Int));
                    amount0Int = -int256(operateWithIdsVariables_.operateCollateralAmount0);
                }
                if (amount1Int >= 0) {
                    // Handle supply amount for token1
                    operateWithIdsVariables_.operateCollateralAmount1 = getUint(getIds_[3], uint256(amount1Int));
                    amount1Int = int256(operateWithIdsVariables_.operateCollateralAmount1);
                } else {
                    // Handle withdraw amount for token1
                    operateWithIdsVariables_.operateCollateralAmount1 = getUint(getIds_[3], uint256(-amount1Int));
                    amount1Int = -int256(operateWithIdsVariables_.operateCollateralAmount1);
                }

                actionData_ = abi.encode(amount0Int, amount1Int, 0, 0, address(this));
            }
        } else if (positionType_ == 4) {
            if (_isNewPosition(nftId_)) {
                (, PositionParams memory positionParams_) = abi.decode(actionData_, (uint256, PositionParams));
                operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], positionParams_.amount0);
                operateWithIdsVariables_.operateDebtAmount1 = getUint(getIds_[5], positionParams_.amount1);

                positionParams_.amount0 = operateWithIdsVariables_.operateDebtAmount0;
                positionParams_.amount1 = operateWithIdsVariables_.operateDebtAmount1;
                positionParams_.to = address(this);
                actionData_ = abi.encode(4, positionParams_);
            } else {
                (int256 amount0Int, int256 amount1Int, , , ) = abi.decode(actionData_, (int256, int256, uint256, uint256, address));
                if (amount0Int >= 0) {
                    // Handle borrow amount for token0
                    operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], uint256(amount0Int));
                    amount0Int = int256(operateWithIdsVariables_.operateDebtAmount0);
                } else {
                    // Handle payback amount for token0
                    operateWithIdsVariables_.operateDebtAmount0 = getUint(getIds_[4], uint256(-amount0Int));
                    amount0Int = -int256(operateWithIdsVariables_.operateDebtAmount0);
                }
                if (amount1Int >= 0) {
                    // Handle borrow amount for token1
                    operateWithIdsVariables_.operateDebtAmount1 = getUint(getIds_[5], uint256(amount1Int));
                    amount1Int = int256(operateWithIdsVariables_.operateDebtAmount1);
                } else {
                    // Handle payback amount for token1
                    operateWithIdsVariables_.operateDebtAmount1 = getUint(getIds_[5], uint256(-amount1Int));
                    amount1Int = -int256(operateWithIdsVariables_.operateDebtAmount1);
                }

                actionData_ = abi.encode(amount0Int, amount1Int, 0, 0, address(this));
            }
        }

        IFluidDexV2(FLUID_DEX_V2_MM_ADDRESS).operate(
            nftId_,
            positionIndex_,
            actionData_
        );

        _eventName = "LogOperateWithIds(uint8,uint256,uint256,bytes,uint256[],uint256[])";
        _eventParam = abi.encode(
            positionType_,
            nftId_,
            positionIndex_,
            actionData_,
            getIds_,
            setIds_
        );

        // Set the setIds_
        setUint(setIds_[0], nftId_);
        setUint(setIds_[1], positionIndex_);
        setUint(setIds_[2], operateWithIdsVariables_.operateCollateralAmount0);
        setUint(setIds_[3], operateWithIdsVariables_.operateCollateralAmount1);
        setUint(setIds_[4], operateWithIdsVariables_.operateDebtAmount0);
        setUint(setIds_[5], operateWithIdsVariables_.operateDebtAmount1);
    }

    function changeEMode(
        uint256 nftId_,
        uint256 newEmode_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
       IFluidDexV2(FLUID_DEX_V2_MM_ADDRESS).changeEmode(nftId_, newEmode_);

       _eventName = "LogChangeEmode(uint256,uint256)";
       _eventParam = abi.encode(nftId_, newEmode_);
    }
}

contract ConnectV2FluidDexV2MMPolygon is FluidDexV2MMConnector {
    string public constant name = "Fluid-Dex-v2-MM-v1.0";
}
