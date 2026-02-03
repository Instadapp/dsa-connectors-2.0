// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FluidDexV2Helpers {
    // @TODO: Update the MM address
    address internal constant FLUID_DEX_V2_MM_ADDRESS = 0x0000000000000000000000000000000000000000;

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

    // modifier validateIds
}
