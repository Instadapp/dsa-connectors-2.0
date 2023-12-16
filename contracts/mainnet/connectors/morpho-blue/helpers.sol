//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Id, IMorpho, MarketParams, Position, Market} from "./interfaces/IMorpho.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";
import {MorphoBalancesLib} from "./libraries/periphery/MorphoBalancesLib.sol";
import {UtilsLib} from "./libraries/UtilsLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";

abstract contract Helpers is Stores, Basic {
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using UtilsLib for uint256;

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
    ) internal returns (MarketParams memory, uint256 _amt) {
        _amt = getUint(_getId, _assets);

        bool _isEth = _mode == Mode.Collateral
            ? _marketParams.collateralToken == ethAddr
            : _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        // Check for max value
        if (_assets == type(uint256).max) {
            uint256 _maxAvailable = _isEth
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );
            if (_mode == Mode.Repay) {
                uint256 _amtDebt = getPaybackBalance(_marketParams, _onBehalf);
                _amt = _maxAvailable.min(_amtDebt); // TODO: Ask
            } else {
                _amt = _maxAvailable;
            }
        }

        // Perform conversion if necessary
        convertEthToWeth(true, TokenInterface(_marketParams.loanToken), _amt);

        return (_marketParams, _amt);
    }

    /// @notice Handles Eth to Weth conversion if shares are provided.
    function _performEthToWethSharesConversion(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        uint256 _getId,
        bool _isRepay
    ) internal returns (MarketParams memory, uint256 _assets) {
        uint256 _shareAmt = getUint(_getId, _shares);
        bool _isEth = _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        // Handle the max share case
        if (_shares == type(uint256).max) {
            uint256 _maxAvailable = _isEth
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );

            // If it's repay calculate the min of balance available and debt to repay
            if (_isRepay) {
                _assets = _maxAvailable.min(
                    getPaybackBalance(_marketParams, _onBehalf) // TODO: Ask
                );
            } else {
                _assets = _maxAvailable;
            }
        } else {
            (
                uint256 totalSupplyAssets,
                uint256 totalSupplyShares,
                ,

            ) = MORPHO_BLUE.expectedMarketBalances(_marketParams);

            _assets = _toAssetsUp(
                _shareAmt,
                totalSupplyAssets,
                totalSupplyShares
            );
        }

        // Perform ETH to WETH conversion if necessary
        convertEthToWeth(
            true,
            TokenInterface(_marketParams.loanToken),
            _assets
        );

        return (_marketParams, _assets);
    }

    /// @notice Returns the payback balance in assets.
    function getPaybackBalance(
        MarketParams memory _marketParams,
        address _onBehalf
    ) internal view returns (uint256 _assets) {
        Id _id = _marketParams.id();

        uint256 _shareAmt = MORPHO_BLUE.position(_id, _onBehalf).supplyShares;

        (uint256 totalSupplyAssets, uint256 totalSupplyShares, , ) = MORPHO_BLUE
            .expectedMarketBalances(_marketParams);

        _assets = _toAssetsUp(_shareAmt, totalSupplyAssets, totalSupplyShares);
    }

    /// @notice Calculates the value of `shares` quoted in assets, rounding up.
    function _toAssetsUp(
        uint256 _shares,
        uint256 _totalAssets,
        uint256 _totalShares
    ) internal pure returns (uint256) {
        return
            _mulDivUp(
                _shares,
                _totalAssets + VIRTUAL_ASSETS,
                _totalShares + VIRTUAL_SHARES
            );
    }

    /// @notice Returns (`x` * `y`) / `d` rounded up.
    function _mulDivUp(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        return (x * y + (d - 1)) / d;
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
