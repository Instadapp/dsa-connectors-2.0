//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Spark Rewards.
 * @dev Claim spark rewards.
 */

import {TokenInterface} from "../../common/interfaces.sol";
import {Stores} from "../../common/stores.sol";
import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";

abstract contract IncentivesConnector is Helpers, Events {
    /**
     * @dev Claim Pending Rewards.
     * @notice Claim Pending Rewards from Spark incentives contract.
     * @param assets Array of pool addresses.
     * @param amt The amount of reward to claim. (uint(-1) for max)
     * @param reward The address of reward token to claim.
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of rewards claimed.
     */
    function claim(
        address[] calldata assets,
        uint256 amt,
        address reward,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);

        require(assets.length > 0, "invalid-assets");

        TokenInterface weth = TokenInterface(wethAddr);
        uint256 wethAmountBefore = weth.balanceOf(address(this));

        _amt = SPARK_INCENTIVES.claimRewards(
            assets,
            _amt,
            address(this),
            reward
        );

        uint256 wethAmountDiff = weth.balanceOf(address(this)) -
            wethAmountBefore;
        convertWethToEth(wethAmountDiff > 0, weth, wethAmountDiff);

        setUint(setId, _amt);

        _eventName = "LogClaimed(address[],uint256,uint256,uint256)";
        _eventParam = abi.encode(assets, _amt, getId, setId);
    }

    /**
     * @dev Claim All Pending Rewards.
     * @notice Claim All Pending Rewards from Spark incentives contract.
     * @param assets Pool address array.
     */
    function claimAll(
        address[] calldata assets
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        require(assets.length > 0, "invalid-assets");
        uint256[] memory _amts = new uint256[](assets.length);
        address[] memory _rewards = new address[](assets.length);

        TokenInterface weth = TokenInterface(wethAddr);
        uint256 wethAmountBefore = weth.balanceOf(address(this));

        (_rewards, _amts) = SPARK_INCENTIVES.claimAllRewards(
            assets,
            address(this)
        );

        uint256 wethAmountDiff = weth.balanceOf(address(this)) -
            wethAmountBefore;
        convertWethToEth(wethAmountDiff > 0, weth, wethAmountDiff);

        _eventName = "LogAllClaimed(address[],address[],uint256[])";
        _eventParam = abi.encode(assets, _rewards, _amts);
    }
}

contract ConnectV2SparkIncentives is IncentivesConnector {
    string public constant name = "Spark-Incentives-v1";
}
