// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FluidDexV2Helpers {
    address internal constant FLUID_DEX_V2_MM_ADDRESS = 0x92fC6445a6d57fCA94c3B847E80504B95e2D9e2F;

    modifier validatePositionType(uint8 positionType_) {
        require(
         positionType_ == 1 || // Normal Collateral
         positionType_ == 2 || // Normal Debt
         positionType_ == 3 || // Smart Collateral
         positionType_ == 4 , // Smart Debt
         "Invalid DEX V2 position type");
        _;
    }

    /// @dev nftId 0 mints a new NFT, positionIndex 0 opens a new position on an existing NFT; both take the create layout
    function _isNewPosition(uint256 nftId_, uint256 positionIndex_) internal pure returns (bool) {
        return nftId_ == 0 || positionIndex_ == 0;
    }

    /// @dev type(int256).min means "withdraw / pay back everything" to the Money Market and must not be negated
    function _isMaxAmount(int256 amount_) internal pure returns (bool) {
        return amount_ == type(int256).min;
    }

    function _getActualOperateAmount(uint256 amount_) internal pure returns (uint256) {
        if (amount_ == 0) {
            return 0;
        }

        if (amount_ == type(uint256).max || amount_ == uint256(type(int256).max)) {
            return amount_;
        }
        
        return amount_ - 1;
    }
}
