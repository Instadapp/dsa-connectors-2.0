//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface SparkIncentivesInterface {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    function claimAllRewards(
        address[] calldata assets,
        address to
    )
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}
