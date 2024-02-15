//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards {
  function stake(uint256 amount) external;
  function withdraw(uint256 amount) external;
  function getReward() external;
  function balanceOf(address account) external view returns(uint256);
  function rewardsToken() external view returns (IERC20);
  function stakingToken() external view returns (IERC20);
}
