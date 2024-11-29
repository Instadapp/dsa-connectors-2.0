//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISparkPsm {
    /**
     * @notice Function that swaps Dai into `gem`.
     * @dev Reverts if `tout` is set to `HALTED`.
     * @param usr The destination of the bought gems.
     * @param gemAmt The amount of gem to buy. [`gem` precision].
     * @return daiInWad The amount of Dai required to sell.
     */
    function buyGem(address usr, uint256 gemAmt) external returns (uint256 daiInWad);
}
