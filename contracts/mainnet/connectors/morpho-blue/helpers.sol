//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Id, IMorpho, MarketParams, Position, Market} from "./interfaces/IMorpho.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";
import {MorphoBalancesLib} from "./libraries/periphery/MorphoBalancesLib.sol";
import {UtilsLib} from "./libraries/UtilsLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";

abstract contract Helpers is Stores, Basic {
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using UtilsLib for uint256;
    using SharesMathLib for uint256;

    IMorpho public constant MORPHO_BLUE =
        IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0); // TODO: Update

    uint256 internal constant MARKET_PARAMS_BYTES_LENGTH = 5 * 32;

    /// @dev The number of virtual assets of 1 enforces a conversion rate between shares and assets when a market is
    /// empty.
    uint256 internal constant VIRTUAL_ASSETS = 1;

    /// @dev The number of virtual shares has been chosen low enough to prevent overflows, and high enough to ensure
    /// high precision computations.
    uint256 internal constant VIRTUAL_SHARES = 1e6;

    enum Mode {
        Collateral,
        Repay,
        Supply
    }

    /// @notice Handles Eth to Weth conversion if assets are provided.
    function _performEthToWethConversion(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        uint256 _getId,
        Mode _mode
    ) internal returns (Id _id, MarketParams memory, uint256 _amt) {
        _amt = getUint(_getId, _assets);

        bool _isEth = _mode == Mode.Collateral
            ? _marketParams.collateralToken == ethAddr
            : _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Check for max value
        if (_assets == type(uint256).max) {
            uint256 _maxAvailable = _isEth
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );
            if (_mode == Mode.Repay) {
                uint256 _amtDebt = getPaybackBalance(_id, _marketParams, _onBehalf);
                _amt = UtilsLib.min(_maxAvailable, _amtDebt);
            } else {
                _amt = _maxAvailable;
            }
        }

        // Perform conversion if necessary
        convertEthToWeth(true, TokenInterface(_marketParams.loanToken), _amt);

        return (_id, _marketParams, _amt);
    }

    /// @notice Handles Eth to Weth conversion if shares are provided.
    function _performEthToWethSharesConversion(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        uint256 _getId,
        bool _isRepay
    ) internal returns (Id _id, MarketParams memory, uint256 _assets) {
        uint256 _shareAmt = getUint(_getId, _shares);
        bool _isEth = _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Handle the max share case
        if (_shares == type(uint256).max) {
            uint256 _maxAvailable = _isEth
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );

            // If it's repay calculate the min of balance available and debt to repay
            if (_isRepay) {
                _assets = UtilsLib.min(_maxAvailable, getPaybackBalance(_id, _marketParams, _onBehalf));
            } else {
                _assets = _maxAvailable;
            }
        } else {
            (
                uint256 totalSupplyAssets,
                uint256 totalSupplyShares,
                ,

            ) = MORPHO_BLUE.expectedMarketBalances(_marketParams);

            _assets = _shareAmt.toAssetsUp(totalSupplyAssets, totalSupplyShares);
        }

        // Perform ETH to WETH conversion if necessary
        convertEthToWeth(
            true,
            TokenInterface(_marketParams.loanToken),
            _assets
        );

        return (_id, _marketParams, _assets);
    }

    /// @notice Returns the payback balance in assets.
    function getPaybackBalance(
        Id _id,
        MarketParams memory _marketParams,
        address _onBehalf
    ) internal view returns (uint256 _assets) {
        uint256 _shareAmt = MORPHO_BLUE.position(_id, _onBehalf).supplyShares;

        (uint256 totalSupplyAssets, uint256 totalSupplyShares, , ) = MORPHO_BLUE
            .expectedMarketBalances(_marketParams);

        _assets = _shareAmt.toAssetsUp(totalSupplyAssets, totalSupplyShares);
    }

    function updateTokenAddresses(
        MarketParams memory _marketParams
    ) internal pure returns (MarketParams memory) {
        _marketParams.loanToken = _marketParams.loanToken == ethAddr
            ? wethAddr
            : _marketParams.loanToken;

        _marketParams.collateralToken = _marketParams.collateralToken == ethAddr
            ? wethAddr
            : _marketParams.collateralToken;

        return _marketParams;
    }
}
