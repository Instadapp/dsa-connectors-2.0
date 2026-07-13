//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { VTokenInterface, NativeVTokenInterface } from "./interface.sol";

error VenusErrorCode(uint256 code);

abstract contract VenusResolver is Events, Helpers {
    function _isVTokenCallOk(bool success, bytes memory data)
        internal
        pure
        returns (bool)
    {
        if (!success) return false;
        if (data.length == 0) return true;
        if (data.length == 32) {
            return abi.decode(data, (uint256)) == 0;
        }
        return false;
    }

    function _validateVTokenCall(
        bool success,
        bytes memory data,
        string memory errMsg
    ) internal pure {
        if (!success) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
            revert(errMsg);
        }
        if (data.length == 32) {
            uint256 code = abi.decode(data, (uint256));
            if (code != 0) revert VenusErrorCode(code);
        }
    }

    function _callVToken(
        address vToken,
        bytes memory callData,
        string memory errMsg
    ) internal {
        (bool success, bytes memory data) = vToken.call(callData);
        _validateVTokenCall(success, data, errMsg);
    }

    function _callVTokenWithValue(
        address vToken,
        bytes memory callData,
        uint256 value,
        string memory errMsg
    ) internal {
        (bool success, bytes memory data) = vToken.call{value: value}(callData);
        _validateVTokenCall(success, data, errMsg);
    }

    function _callVTokenWithFallback(
        address vToken,
        bytes memory primaryData,
        bytes memory fallbackData,
        uint256 value,
        string memory errMsg
    ) internal {
        (bool success, bytes memory data) = vToken.call{value: value}(primaryData);
        if (!_isVTokenCallOk(success, data)) {
            (success, data) = vToken.call{value: value}(fallbackData);
        }
        _validateVTokenCall(success, data, errMsg);
    }

    function _vTokenBalanceOf(address vToken, address account)
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory data) = vToken.staticcall(
            abi.encodeWithSignature("balanceOf(address)", account)
        );
        require(success && data.length == 32, "venus-balance-of-failed");
        return abi.decode(data, (uint256));
    }

    function _borrowBalanceCurrent(address vToken, address account)
        internal
        returns (uint256)
    {
        (bool success, bytes memory data) = vToken.call(
            abi.encodeWithSignature("borrowBalanceCurrent(address)", account)
        );
        require(success && data.length == 32, "venus-borrow-balance-failed");
        return abi.decode(data, (uint256));
    }

    function deposit(
        address token,
        address vToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;

        // Enter market before mint so Comptroller hooks succeed on current Venus deployments.
        if (!_isMarketEntered(vToken)) {
            _enterMarket(vToken);
        }

        if (isBnb) {
            NativeVTokenInterface nativeVToken = NativeVTokenInterface(vToken);
            _amt = _amt == type(uint256).max
                ? address(this).balance
                : _amt;
            nativeVToken.mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            VTokenInterface erc20VToken = VTokenInterface(vToken);
            _amt = _amt == type(uint256).max
                ? tokenContract.balanceOf(address(this))
                : _amt;
            approve(tokenContract, vToken, _amt);
            erc20VToken.mint(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, vToken, _amt, getId, setId);
    }

    function depositWithoutCollateral(
        address token,
        address vToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;

        if (isBnb) {
            NativeVTokenInterface nativeVToken = NativeVTokenInterface(vToken);
            _amt = _amt == type(uint256).max
                ? address(this).balance
                : _amt;
            nativeVToken.mint{value: _amt}();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            VTokenInterface erc20VToken = VTokenInterface(vToken);
            _amt = _amt == type(uint256).max
                ? tokenContract.balanceOf(address(this))
                : _amt;
            approve(tokenContract, vToken, _amt);
            erc20VToken.mint(_amt);
        }

        setUint(setId, _amt);

        _eventName = "LogDepositWithoutCollateral(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, vToken, _amt, getId, setId);
    }

    function withdraw(
        address token,
        address vToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;
        NativeVTokenInterface nativeVToken = NativeVTokenInterface(vToken);
        VTokenInterface erc20VToken = VTokenInterface(vToken);

        uint256 initialBal = isBnb
            ? address(this).balance
            : TokenInterface(token).balanceOf(address(this));

        if (_amt == type(uint256).max) {
            uint256 vTokBal = isBnb
                ? nativeVToken.balanceOf(address(this))
                : erc20VToken.balanceOf(address(this));
            uint256 code = isBnb
                ? nativeVToken.redeem(vTokBal)
                : erc20VToken.redeem(vTokBal);
            require(code == 0, "venus-withdraw-failed");
        } else {
            uint256 code = isBnb
                ? nativeVToken.redeemUnderlying(_amt)
                : erc20VToken.redeemUnderlying(_amt);
            require(code == 0, "venus-withdraw-failed");
        }

        uint256 finalBal = isBnb
            ? address(this).balance
            : TokenInterface(token).balanceOf(address(this));
        uint256 actualAmt = sub(finalBal, initialBal);

        setUint(setId, actualAmt);

        _eventName = "LogWithdraw(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, vToken, actualAmt, getId, setId);
    }

    function borrow(
        address token,
        address vToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;
        uint256 code = isBnb
            ? NativeVTokenInterface(vToken).borrow(_amt)
            : VTokenInterface(vToken).borrow(_amt);
        require(code == 0, "venus-borrow-failed");

        setUint(setId, _amt);

        _eventName = "LogBorrow(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, vToken, _amt, getId, setId);
    }

    function repay(
        address token,
        address vToken,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;
        TokenInterface tokenContract = TokenInterface(token);
        NativeVTokenInterface nativeVToken = NativeVTokenInterface(vToken);
        VTokenInterface erc20VToken = VTokenInterface(vToken);

        if (_amt == type(uint256).max) {
            uint256 bal = isBnb
                ? address(this).balance
                : tokenContract.balanceOf(address(this));
            uint256 debt = isBnb
                ? nativeVToken.borrowBalanceCurrent(address(this))
                : erc20VToken.borrowBalanceCurrent(address(this));
            _amt = bal > debt ? debt : bal;
        }

        if (isBnb) {
            require(
                nativeVToken.repayBorrow{value: _amt}() == 0,
                "venus-repay-failed"
            );
        } else {
            approve(tokenContract, vToken, _amt);
            require(erc20VToken.repayBorrow(_amt) == 0, "venus-repay-failed");
        }

        setUint(setId, _amt);

        _eventName = "LogRepay(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, vToken, _amt, getId, setId);
    }

    function repayOnBehalfOf(
        address token,
        address vToken,
        uint256 amt,
        address onBehalfOf,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);
        bool isBnb = token == bnbAddr;
        TokenInterface tokenContract = TokenInterface(token);

        if (_amt == type(uint256).max) {
            uint256 bal = isBnb
                ? address(this).balance
                : tokenContract.balanceOf(address(this));
            uint256 debt = _borrowBalanceCurrent(vToken, onBehalfOf);
            _amt = bal > debt ? debt : bal;
        }

        if (isBnb) {
            _callVTokenWithFallback(
                vToken,
                abi.encodeWithSignature("repayBorrowBehalf(address)", onBehalfOf),
                abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", onBehalfOf, _amt),
                _amt,
                "venus-repay-behalf-failed"
            );
        } else {
            approve(tokenContract, vToken, _amt);
            _callVTokenWithFallback(
                vToken,
                abi.encodeWithSignature("repayBorrowBehalf(address,uint256)", onBehalfOf, _amt),
                abi.encodeWithSignature("repayBorrowBehalf(address)", onBehalfOf),
                0,
                "venus-repay-behalf-failed"
            );
        }

        setUint(setId, _amt);

        _eventName = "LogRepayOnBehalfOf(address,address,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            token,
            vToken,
            _amt,
            onBehalfOf,
            getId,
            setId
        );
    }

    function enableCollateral(address[] calldata vTokens)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(vTokens.length > 0, "venus-empty-vtokens");
        comptroller.enterMarkets(vTokens);

        _eventName = "LogEnableCollateral(address[])";
        _eventParam = abi.encode(vTokens);
    }

    function disableCollateral(address[] calldata vTokens)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(vTokens.length > 0, "venus-empty-vtokens");
        uint256 len = vTokens.length;
        for (uint256 i = 0; i < len; i++) {
            comptroller.exitMarket(vTokens[i]);
        }

        _eventName = "LogDisableCollateral(address[])";
        _eventParam = abi.encode(vTokens);
    }
}

contract ConnectV2VenusCoreBSC is VenusResolver {
    string public constant name = "VenusCore-BSC-v1.0";
}
