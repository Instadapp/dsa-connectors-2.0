//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { Basic } from "../../common/basic.sol";
import { AavePoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";

abstract contract Helpers is Basic {
	/**
	 * @dev Aave Pool Provider
	 */
	AavePoolProviderInterface internal constant aaveProvider =
		AavePoolProviderInterface(0xcfBf336fe147D643B9Cb705648500e101504B16d);

	/**
	 * @dev Aave Pool Data Provider
	 */
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0x08795CFE08C7a81dCDFf482BbAAF474B240f31cD);

	/**
	 * @dev Aave Referral Code
	 */
	uint16 internal constant referralCode = 3228;

	/**
	 * @dev Checks if collateral is enabled for an asset
	 * @param token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 */

	function getIsColl(address token) internal view returns (bool isCol) {
		(, , , , , , , , isCol) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	/**
	 * @dev Get total debt balance & fee for an asset
	 * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
	 */
	function getPaybackBalance(address token, uint256 rateMode)
		internal
		view
		returns (uint256)
	{
		(, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
			.getUserReserveData(token, address(this));
		return rateMode == 1 ? stableDebt : variableDebt;
	}

	/**
	 * @dev Get OnBehalfOf user's total debt balance & fee for an asset
	 * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
	 */
	function getOnBehalfOfPaybackBalance(address token, uint256 rateMode, address onBehalfOf)
		internal
		view
		returns (uint256)
	{
		(, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
			.getUserReserveData(token, onBehalfOf);
		return rateMode == 1 ? stableDebt : variableDebt;
	}

	/**
	 * @dev Get total collateral balance for an asset
	 * @param token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 */
	function getCollateralBalance(address token)
		internal
		view
		returns (uint256 bal)
	{
		(bal, , , , , , , , ) = aaveData.getUserReserveData(
			token,
			address(this)
		);
	}

	/**
	 * @dev Get debt token address for an asset
	 * @param token token address of the asset
	 * @param rateMode Debt type: stable-1, variable-2
	 */
	function getDTokenAddr(address token, uint256 rateMode)
		internal
		view
		returns(address dToken)
	{
		if (rateMode == 1) {
			(, dToken, ) = aaveData.getReserveTokensAddresses(token);
		} else {
			(, , dToken) = aaveData.getReserveTokensAddresses(token);
		}
	}
}
