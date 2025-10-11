//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {TokenInterface} from "./interfaces.sol";
import {Stores} from "./stores.sol";
import {DSMath} from "./math.sol";

abstract contract Basic is DSMath, Stores {
    function convert18ToDec(
        uint _dec,
        uint256 _amt
    ) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(
        uint _dec,
        uint256 _amt
    ) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(
        TokenInterface token
    ) internal view returns (uint _amt) {
        _amt = address(token) == xplAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getTokensDec(
        TokenInterface buyAddr,
        TokenInterface sellAddr
    ) internal view returns (uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == xplAddr ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == xplAddr ? 18 : sellAddr.decimals();
    }

    function encodeEvent(
        string memory eventName,
        bytes memory eventParam
    ) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeXplAddress(
        address buy,
        address sell
    ) internal pure returns (TokenInterface _buy, TokenInterface _sell) {
        _buy = buy == xplAddr ? TokenInterface(wxplAddr) : TokenInterface(buy);
        _sell = sell == xplAddr
            ? TokenInterface(wxplAddr)
            : TokenInterface(sell);
    }

    function changeXplAddrToWxplAddr(
        address token
    ) internal pure returns (address tokenAddr) {
        tokenAddr = token == xplAddr ? wxplAddr : token;
    }

    function convertXplToWxpl(
        bool isXpl,
        TokenInterface token,
        uint amount
    ) internal {
        if (isXpl) token.deposit{value: amount}();
    }

    function convertWxplToXpl(
        bool isXpl,
        TokenInterface token,
        uint amount
    ) internal {
        if (isXpl) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}
