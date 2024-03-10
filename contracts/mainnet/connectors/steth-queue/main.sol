//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {TokenInterface} from "../../common/interfaces.sol";
import {Events} from "./events.sol";
import {IFluidStETHQueue} from "./interfaces.sol";
import {Basic} from "../../common/basic.sol";

abstract contract StethQueueConnector is Events, Basic {
    address public constant FLUID_STETH_QUEUE =
        0xEb6643733c5E7CaB6B27D98C8CFDc647f8112a96;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function queueSteth(
        uint256 stETHAmount_,
        uint256 ethBorrowAmount_,
        uint256 getId_,
        uint256 setId_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 stETHAmt_ = getUint(getId_, stETHAmount_);

        IFluidStETHQueue fluidStethContract_ = IFluidStETHQueue(
            FLUID_STETH_QUEUE
        );

        stETHAmt_ = stETHAmt_ == type(uint256).max
            ? TokenInterface(STETH).balanceOf(address(this))
            : stETHAmt_;

        approve(TokenInterface(address(STETH)), FLUID_STETH_QUEUE, stETHAmt_);
        uint256 requestIdFrom_ = fluidStethContract_.queue(
            ethBorrowAmount_,
            stETHAmount_,
            address(this),
            address(this)
        ); // todo: confirm

        setUint(setId_, requestIdFrom_);
        _eventName = "LogQueueSteth(uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            stETHAmount_,
            ethBorrowAmount_,
            requestIdFrom_,
            getId_,
            setId_
        );
    }

    function claimSteth(
        uint256 nftId_,
        uint256 getId_,
        uint256 setIdClaimedAmt_,
        uint256 setIdRepayAmt_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 nftIdNum_ = getUint(getId_, nftId_);

        IFluidStETHQueue fluidStethContract_ = IFluidStETHQueue(
            FLUID_STETH_QUEUE
        );

        (uint256 claimedAmount_, uint256 repayAmount_) = fluidStethContract_
            .claim(address(this), nftIdNum_);

        setUint(setIdClaimedAmt_, claimedAmount_);
        setUint(setIdRepayAmt_, repayAmount_);
        _eventName = "LogClaimSteth(uint256,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            nftId_,
            claimedAmount_,
            repayAmount_,
            getId_,
            setIdClaimedAmt_,
            setIdRepayAmt_
        );
    }
}

contract ConnectV2StethQueueFluid is StethQueueConnector {
    string public constant name = "Steth-Queue-Fluid-v1.0";
}
