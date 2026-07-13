//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { ComptrollerInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ComptrollerInterface internal constant comptroller =
        ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384);

    function _enterMarket(address vToken) internal {
        address[] memory markets = new address[](1);
        markets[0] = vToken;
        comptroller.enterMarkets(markets);
    }

    function _isMarketEntered(address vToken) internal view returns (bool) {
        address[] memory assets = comptroller.getAssetsIn(address(this));
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == vToken) return true;
        }
        return false;
    }
}
