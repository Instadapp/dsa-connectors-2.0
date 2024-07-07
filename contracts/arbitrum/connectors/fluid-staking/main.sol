//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Fluid Staking.
 * @dev Stake Fluid for earning rewards.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { IStakingRewards } from "./interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Main is Basic, Events {

  /**
    * @dev Deposit ERC20.
    * @notice Deposit Tokens to staking pool.
    * @param stakingPool staking pool address.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setId ID stores the amount of staked tokens.
  */
  function deposit(
    address stakingPool,
    uint amt,
    uint getId,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);
    
    IStakingRewards stakingContract = IStakingRewards(stakingPool);
    IERC20 stakingTokenContract = stakingContract.stakingToken();

    _amt = _amt == type(uint256).max 
      ? stakingTokenContract.balanceOf(address(this)) 
      : _amt;

    approve(TokenInterface(address(stakingTokenContract)), address(stakingContract), _amt);
    stakingContract.stake(_amt);

    setUint(setId, _amt);
    _eventName = "LogDeposit(address,uint256,uint256,uint256)";
    _eventParam = abi.encode(stakingPool, _amt, getId, setId);
  }

  /**
    * @dev Withdraw ERC20.
    * @notice Withdraw Tokens from the staking pool.
    * @param stakingPool staking pool address.
    * @param amt staking token amount.
    * @param getId ID to retrieve amount.
    * @param setIdAmount ID stores the amount of stake tokens withdrawn.
    * @param setIdReward ID stores the amount of reward tokens claimed.
  */
  function withdraw(
    address stakingPool,
    uint amt,
    uint getId,
    uint setIdAmount,
    uint setIdReward
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    uint _amt = getUint(getId, amt);

    IStakingRewards stakingContract = IStakingRewards(stakingPool);
    IERC20 rewardsToken = stakingContract.rewardsToken();

    _amt = _amt == type(uint256).max 
      ? stakingContract.balanceOf(address(this))
      : _amt;

    uint intialBal = rewardsToken.balanceOf(address(this));
    stakingContract.withdraw(_amt);
    stakingContract.getReward();

    uint rewardAmt = rewardsToken.balanceOf(address(this)) - intialBal;

    setUint(setIdAmount, _amt);
    setUint(setIdReward, rewardAmt);
    {
    _eventName = "LogWithdrawAndClaimedReward(address,uint256,uint256,uint256,uint256,uint256)";
    _eventParam = abi.encode(stakingPool, _amt, rewardAmt, getId, setIdAmount, setIdReward);
    }
  }

  /**
    * @dev Claim Reward.
    * @notice Claim Pending Rewards of tokens staked.
    * @param stakingPool staking pool address.
    * @param setId ID stores the amount of reward tokens claimed.
  */
  function claimReward(
    address stakingPool,
    uint setId
  ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    IStakingRewards stakingContract = IStakingRewards(stakingPool);
    IERC20 rewardsToken = stakingContract.rewardsToken();

    uint intialBal = rewardsToken.balanceOf(address(this));
    stakingContract.getReward();
    uint finalBal = rewardsToken.balanceOf(address(this));

    uint rewardAmt = finalBal - intialBal;

    setUint(setId, rewardAmt);
    _eventName = "LogClaimedReward(address,address,uint256,uint256)";
    _eventParam = abi.encode(stakingPool, address(rewardsToken), rewardAmt, setId);
  }

}

contract ConnectV2StakeFluidArbitrum is Main {
    string public constant name = "Stake-Fluid-v1.0";
}