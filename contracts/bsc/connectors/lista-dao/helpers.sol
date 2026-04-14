//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../common/stores.sol";
import "../../common/basic.sol";
import "../../common/interfaces.sol";
import {
    Id,
    IMoolah,
    MarketParams,
    Position,
    Market
} from "./interfaces/IMoolah.sol";
import {MoolahBalancesLib} from "./libraries/periphery/MoolahBalancesLib.sol";
import {UtilsLib} from "./libraries/UtilsLib.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";
import {SharesMathLib} from "./libraries/SharesMathLib.sol";

interface IProvider {
    function supplyCollateral(
        MarketParams memory marketParams,
        address onBehalf,
        bytes memory data
    ) external payable;

    function withdrawCollateral(
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        address receiver
    ) external;

    function borrow(
        MarketParams calldata marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external;
}

abstract contract Helpers is Stores, Basic {
    using MoolahBalancesLib for IMoolah;
    using MarketParamsLib for MarketParams;
    using UtilsLib for uint256;
    using SharesMathLib for uint256;

    IMoolah public constant MOOLAH =
        IMoolah(0x8F73b65B4caAf64FBA2aF91cC5D4a2A1318E5D8C);

    /// @notice Handles Bnb to Wbnb conversion if assets are provided.
    function _performBnbToWbnbConversion(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        bool _isModeCollateral
    ) internal returns (Id _id, MarketParams memory, uint256 _amt) {
        _amt = getUint(_getId, _assets);

        bool _isBnb = _isModeCollateral
            ? _marketParams.collateralToken == bnbAddr
            : _marketParams.loanToken == bnbAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Check for max value
        if (_assets == type(uint256).max) {
            _amt = _isBnb
                ? address(this).balance
                : _isModeCollateral
                    ? TokenInterface(_marketParams.collateralToken).balanceOf(
                        address(this)
                    )
                    : TokenInterface(_marketParams.loanToken).balanceOf(
                        address(this)
                    );
        }

        // Perform bnb to wbnb conversion if necessary
        convertBnbToWbnb(
            _isBnb,
            _isModeCollateral
                ? TokenInterface(_marketParams.collateralToken)
                : TokenInterface(_marketParams.loanToken),
            _amt
        );

        return (_id, _marketParams, _amt);
    }

    /// @notice Handles Bnb to Wbnb conversion if shares are provided.
    function _performBnbToWbnbSharesConversion(
        MarketParams memory _marketParams,
        uint256 _shares,
        uint256 _getId
    ) internal returns (Id _id, MarketParams memory, uint256 _assets) {
        uint256 _shareAmt = getUint(_getId, _shares);
        bool _isBnb = _marketParams.loanToken == bnbAddr;

        _marketParams = updateTokenAddresses(_marketParams);

        _id = _marketParams.id();

        // Handle the max share case
        if (_shares == type(uint256).max) {
            _assets = _isBnb
                ? address(this).balance
                : TokenInterface(_marketParams.loanToken).balanceOf(
                    address(this)
                );
        } else {
            (uint256 totalSupplyAssets, uint256 totalSupplyShares, , ) = MOOLAH
                .expectedMarketBalances(_marketParams);

            _assets = _shareAmt.toAssetsUp(
                totalSupplyAssets,
                totalSupplyShares
            );
        }

        // Perform BNB to WBNB conversion if necessary
        convertBnbToWbnb(
            _isBnb,
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
        Position memory _pos = MOOLAH.position(_id, _onBehalf);
        _borrowedShareAmt = _pos.borrowShares;

        (, , uint256 totalBorrowAssets, uint256 totalBorrowShares) = MOOLAH
            .expectedMarketBalances(_marketParams);

        _assets = _borrowedShareAmt.toAssetsUp(
            totalBorrowAssets,
            totalBorrowShares
        );
    }

    function updateTokenAddresses(
        MarketParams memory _marketParams
    ) internal pure returns (MarketParams memory) {
        _marketParams.loanToken = _marketParams.loanToken == bnbAddr
            ? wbnbAddr
            : _marketParams.loanToken;

        _marketParams.collateralToken = _marketParams.collateralToken == bnbAddr
            ? wbnbAddr
            : _marketParams.collateralToken;

        return _marketParams;
    }
}
