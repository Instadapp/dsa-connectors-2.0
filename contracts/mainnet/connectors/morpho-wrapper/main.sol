//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Basic} from "../../common/basic.sol";
import {TokenInterface} from "../../common/interfaces.sol";
import {IMorphoWrapper} from "./interfaces.sol";
import "./events.sol";

abstract contract MorphoTokenWrapper is Basic, Events {
    address internal constant MORPHO_LEGACY_TOKEN =
        0x9994E35Db50125E0DF82e4c2dde62496CE330999;

    address internal constant MORPHO_WRAPPER =
        0x9D03bb2092270648d7480049d0E58d2FcF0E5123;

    address internal constant MORPHO_TOKEN_NEW =
        0x58D97B57BB95320F9a05dC918Aef65434969c2B2;

    error LessTokensReceived();

    /**
     * @dev Convert MORPHO Legacy to MORPHO New.
     */
    function convertToNewMorpho()
        public
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = TokenInterface(MORPHO_LEGACY_TOKEN).balanceOf(
            address(this)
        );

        uint256 balanceBefore_ = TokenInterface(MORPHO_TOKEN_NEW).balanceOf(
            address(this)
        );

        approve(TokenInterface(MORPHO_LEGACY_TOKEN), MORPHO_WRAPPER, _amt);

        IMorphoWrapper(MORPHO_WRAPPER).depositFor(address(this), _amt);

        uint256 tokensReceived_ = TokenInterface(MORPHO_TOKEN_NEW).balanceOf(
            address(this)
        ) - balanceBefore_;

        if (tokensReceived_ < (_amt - 100)) {
            revert LessTokensReceived();
        }

        _eventName = "LogConvertToNewMorpho(uint256)";
        _eventParam = abi.encode(tokensReceived_);
    }
}

contract ConnectV2MorphoTokenWrapper is MorphoTokenWrapper {
    string public constant name = "Morpho-Token-Wrapper-v1.0";
}
