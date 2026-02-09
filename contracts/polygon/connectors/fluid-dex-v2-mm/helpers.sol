// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FluidDexV2Helpers {
    address internal constant FLUID_DEX_V2_MM_ADDRESS = 0xD8E73B7169C579Cc6c2d08c458Cce3d944a76010;

    modifier validatePositionType(uint8 positionType_) {
        require(
         positionType_ == 1 || // Normal Collateral
         positionType_ == 2 || // Normal Debt
         positionType_ == 3 || // Smart Collateral
         positionType_ == 4 , // Smart Debt
         "Invalid DEX V2 position type");
        _;
    }

    function _isNewPosition(uint256 nftId_) internal pure returns (bool) {
        return nftId_ == 0;
    }

    function _getApproveAmount(uint256 amount_) internal pure returns (uint256) {
        if (amount_ == type(uint256).max || amount_ == uint256(type(int256).max)) {
            return amount_;
        }
        
        return amount_ + 10;
    }
}
