//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Id, MarketParams} from "./interfaces/IMoolah.sol";

contract Events {
    event LogSupplyCollateral(
        Id indexed id,
        address indexed onBehalf,
        uint256 assets,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        Id indexed id,
        address indexed onBehalf,
        uint256 amounts,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        Id indexed id,
        address indexed onBehalf,
        uint256 amounts,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );

    event LogRepay(
        Id indexed id,
        address indexed onBehalf,
        uint256 amounts,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );
}
