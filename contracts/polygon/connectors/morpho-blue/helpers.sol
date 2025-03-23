//SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Id, IMorpho, MarketParams, Position, Market} from "./interfaces/IMorpho.sol";
import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";
import {MorphoBalancesLib} from "./libraries/periphery/MorphoBalancesLib.sol";
import {MorphoLib} from "./libraries/periphery/MorphoLib.sol";
import {UtilsLib} from "./libraries/UtilsLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";

abstract contract Helpers is Stores, Basic {
    using MorphoBalancesLib for IMorpho;
    using MorphoLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using UtilsLib for uint256;
    using SharesMathLib for uint256;

    IMorpho public constant MORPHO_BLUE =
        IMorpho(0x1bF0c2541F820E775182832f06c0B7Fc27A25f67);

    /// @notice Handles Eth to Weth conversion if assets are provided.
    function _performEthToWethConversion(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        bool _isModeCollateral
    ) internal returns (Id _id, MarketParams memory, uint256 _amt) {
        _amt = getUint(_getId, _assets);

        bool _isMatic = _isModeCollateral
            ? _marketParams.collateralToken == maticAddr
            : _marketParams.loanToken == maticAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Check for max value
        if (_assets == type(uint256).max) {
            _amt = _isMatic
                ? address(this).balance
                : _isModeCollateral
                    ? TokenInterface(_marketParams.collateralToken).balanceOf(
                        address(this)
                    )
                    : TokenInterface(_marketParams.loanToken).balanceOf(
                        address(this)
                    );
        }

        // Perform eth to weth conversion if necessary
        convertMaticToWmatic(
            _isMatic,
            _isModeCollateral
                ? TokenInterface(_marketParams.collateralToken)
                : TokenInterface(_marketParams.loanToken),
            _amt
        );

        return (_id, _marketParams, _amt);
    }

    /// @notice Handles Eth to Weth conversion if shares are provided.
    function _performEthToWethSharesConversion(
        MarketParams memory _marketParams,
        uint256 _shares,
        uint256 _getId
    ) internal returns (Id _id, MarketParams memory, uint256 _assets) {
        uint256 _shareAmt = getUint(_getId, _shares);
        bool _isMatic = _marketParams.loanToken == maticAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Handle the max share case
        if (_shares == type(uint256).max) {
            _assets = _isMatic
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );
        } else {
            (
                uint256 totalSupplyAssets,
                uint256 totalSupplyShares,
                ,

            ) = MORPHO_BLUE.expectedMarketBalances(_marketParams);

            _assets = _shareAmt.toAssetsUp(
                totalSupplyAssets,
                totalSupplyShares
            );
        }

        // Perform ETH to WETH conversion if necessary
        convertMaticToWmatic(
            _isMatic,
            TokenInterface(_marketParams.loanToken),
            _assets
        );

        return (_id, _marketParams, _assets);
    }

    /// @notice Returns the borrowed assets and shares of onBehalf.
    function getPaybackBalance(
        Id _id,
        MarketParams memory _marketParams,
        address _onBehalf
    ) internal view returns (uint256 _assets, uint256 _borrowedShareAmt) {
        Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
        _borrowedShareAmt = _pos.borrowShares;

        (, , uint256 totalBorrowAssets, uint256 totalBorrowShares) = MORPHO_BLUE
            .expectedMarketBalances(_marketParams);

        _assets = _borrowedShareAmt.toAssetsUp(
            totalBorrowAssets,
            totalBorrowShares
        );
    }

    function updateTokenAddresses(
        MarketParams memory _marketParams
    ) internal pure returns (MarketParams memory) {
        _marketParams.loanToken = _marketParams.loanToken == maticAddr
            ? wmaticAddr
            : _marketParams.loanToken;

        _marketParams.collateralToken = _marketParams.collateralToken == maticAddr
            ? wmaticAddr
            : _marketParams.collateralToken;

        return _marketParams;
    }
}
