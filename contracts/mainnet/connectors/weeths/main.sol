//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";
import {Basic} from "../../common/basic.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract WEETHSContract is Helpers, Basic, Events {
    /**
     * @dev Mint weETHs through contract through permitable assets.
     * @param asset Asset address to deposit. For eth: `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`,
     * @param assetAmount The amount of asset to deposit. (For max: `uint256(-1)`)
     * @param minShares Minimum amount of shares to mint.
     * @param getId ID to retrieve asset amount.
     * @param setId ID stores the shares amount minted.
     */
    function deposit(
        address asset,
        uint256 assetAmount,
        uint256 minShares,
        uint256 getId,
        uint256 setId
    ) external returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _assetAmount = getUint(getId, assetAmount);

        bool isEth = asset == ethAddr;
        address _asset = isEth ? wethAddr : asset;

        TokenInterface tokenContract = TokenInterface(_asset);

        if (isEth) {
            _assetAmount = _assetAmount == type(uint256).max
                ? address(this).balance
                : _assetAmount;

            convertEthToWeth(isEth, tokenContract, _assetAmount);
        } else {
            _assetAmount = _assetAmount == type(uint256).max
                ? ERC20(asset).balanceOf(address(this))
                : _assetAmount;
        }

        approve(tokenContract, WEETHS, _assetAmount);

        uint256 sharesMinted = WEETHS_DEPOSIT_CONTRACT.deposit(
            ERC20(_asset),
            _assetAmount,
            minShares
        );

        setUint(setId, sharesMinted);

        _eventName = "LogDeposit(address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            asset,
            _assetAmount,
            minShares,
            sharesMinted,
            getId,
            setId
        );
    }
}

contract ConnectV2WEETHS is WEETHSContract {
    string public constant name = "WEETHs-v1.0";
}
