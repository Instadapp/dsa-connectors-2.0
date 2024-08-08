//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
        IMorpho(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);

    /// @notice Handles Eth to Weth conversion if assets are provided.
    function _performEthToWethConversion(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        bool _isModeCollateral
    ) internal returns (Id _id, MarketParams memory, uint256 _amt) {
        _amt = getUint(_getId, _assets);

        bool _isEth = _isModeCollateral
            ? _marketParams.collateralToken == ethAddr
            : _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Check for max value
        if (_assets == type(uint256).max) {
            _amt = _isEth
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
        convertEthToWeth(
            _isEth,
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
        bool _isEth = _marketParams.loanToken == ethAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Handle the max share case
        if (_shares == type(uint256).max) {
            _assets = _isEth
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
        convertEthToWeth(
            _isEth,
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
        _marketParams.loanToken = _marketParams.loanToken == ethAddr
            ? wethAddr
            : _marketParams.loanToken;

        _marketParams.collateralToken = _marketParams.collateralToken == ethAddr
            ? wethAddr
            : _marketParams.collateralToken;

        return _marketParams;
    }
}
