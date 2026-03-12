//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import "./events.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {MoolahBalancesLib} from "./libraries/periphery/MoolahBalancesLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";

abstract contract ListaDaoConnector is Helpers, Events {
    using MarketParamsLib for MarketParams;
    using MoolahBalancesLib for IMoolah;
    using SharesMathLib for uint256;

    /**
     * @notice Supply BNB/ERC20 Token for collateralization.
     * @param _marketParams The market to supply assets to. (For BNB, pass the collateral token as WBNB)
     * @param _assets The amount of assets to supply. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supply(
        MarketParams memory _marketParams,
        address _onBehalf,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);
        Id _id = _marketParams.id();

        address providerAddress = MOOLAH.providers(
            _id,
            _marketParams.collateralToken
        );
        if (providerAddress == address(0)) {
            _amt = _amt == type(uint256).max
                ? TokenInterface(_marketParams.collateralToken).balanceOf(
                    address(this)
                )
                : _amt;

            approve(
                TokenInterface(_marketParams.collateralToken),
                address(MOOLAH),
                _amt
            );

            MOOLAH.supplyCollateral(
                _marketParams,
                _amt,
                _onBehalf,
                new bytes(0)
            );
        } else {
            IProvider provider = IProvider(providerAddress);
            _amt = _amt == type(uint256).max ? address(this).balance : _amt;

            provider.supplyCollateral{value: _amt}(
                _marketParams,
                _onBehalf,
                new bytes(0)
            );
        }

        setUint(_setId, _amt);

        _eventName = "LogSupplyCollateral(bytes32,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _onBehalf, _assets, _getId, _setId);
    }

    /**
     * @notice Withdraws collateral from the market.
     * @param _marketParams The market to withdraw collateral from. (For BNB: use WBNB address)
     * @param _onBehalf The address whose collateral to withdraw (position owner).
     * @param _assets The amount of collateral to withdraw. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount withdrawn.
     */
    function withdraw(
        MarketParams memory _marketParams,
        address _onBehalf,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        if (_amt == type(uint256).max) {
            Position memory _pos = MOOLAH.position(_id, _onBehalf);
            _amt = _pos.collateral;
        }

        address providerAddress = MOOLAH.providers(
            _id,
            _marketParams.collateralToken
        );

        if (providerAddress == address(0)) {
            MOOLAH.withdrawCollateral(
                _marketParams,
                _amt,
                _onBehalf,
                address(this)
            );
        } else {
            IProvider(providerAddress).withdrawCollateral(
                _marketParams,
                _amt,
                _onBehalf,
                address(this)
            );
        }

        setUint(_setId, _amt);

        _eventName = "LogWithdraw(bytes32,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _onBehalf, _amt, _getId, _setId);
    }

    /**
     * @notice Borrows assets.
     * @dev The market to borrow assets from. (For BNB: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to borrow assets from.
     * @param _assets The amount of assets to borrow.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens borrowed.
     */
    function borrow(
        MarketParams memory _marketParams,
        address _onBehalf,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        address providerAddress = MOOLAH.providers(
            _id,
            _marketParams.loanToken
        );

        uint256 _shares;

        if (providerAddress == address(0)) {
            (, _shares) = MOOLAH.borrow(
                _marketParams,
                _amt,
                0,
                _onBehalf,
                address(this)
            );
        } else {
            IProvider(providerAddress).borrow(
                _marketParams,
                _amt,
                0,
                _onBehalf,
                address(this)
            );
        }

        setUint(_setId, _amt);

        _eventName = "LogBorrow(bytes32,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _onBehalf, _amt, _shares, _getId, _setId);
    }

    /**
     * @notice Repay assets.
     * @dev The market to repay assets to. (For BNB: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to repay assets to.
     * @param _assets The amount of assets to repay. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens repaid.
     */
    function repay(
        MarketParams memory _marketParams,
        address _onBehalf,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);
        bool _isBnb = _marketParams.loanToken == bnbAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        if (_amt == type(uint256).max) {
            uint256 _maxDsaBalance = _isBnb
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );

            (uint256 _amtDebt, ) = getPaybackBalance(
                _marketParams.id(),
                _marketParams,
                _onBehalf
            );

            _amt = UtilsLib.min(_maxDsaBalance, _amtDebt);
        }

        convertBnbToWbnb(_isBnb, TokenInterface(_marketParams.loanToken), _amt);

        approve(TokenInterface(_marketParams.loanToken), address(MOOLAH), _amt);

        (_assets, ) = MOOLAH.repay(
            _marketParams,
            _amt,
            0,
            _onBehalf,
            new bytes(0)
        );

        Id _id = _marketParams.id();
        setUint(_setId, _assets);

        _eventName = "LogRepay(bytes32,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _onBehalf, _assets, 0, _getId, _setId);
    }
}

contract ConnectV2ListaDaoBSC is ListaDaoConnector {
    string public constant name = "Lista-DAO-v1.0";
}
