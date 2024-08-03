//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Events {
	event LogDeposit(
		address indexed token,
		uint256 underlyingAmt,
		uint256 sharesReceieved,
		uint256 getId,
		uint256 setId
	);

	event LogMint(
		address indexed token,
		uint256 shareAmt,
		uint256 tokensDeposited,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed token,
		uint256 underlyingAmt,
		uint256 sharedBurned,
		address indexed to,
		uint256 getId,
		uint256 setId
	);

	event LogRedeem(
		address indexed token,
		uint256 shareAmt,
		uint256 underlyingAmtReceieved,
		address to,
		uint256 getId,
		uint256 setId
	);
}