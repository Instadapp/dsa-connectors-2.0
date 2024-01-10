//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import {Id, MarketParams} from "./interfaces/IMorpho.sol";

contract Events {
    event LogSupplyAssets(
        Id indexed id,
        uint256 assets,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );

    event LogSupplyOnBehalf(
        Id indexed id,
        uint256 assets,
        uint256 shares,
        address indexed onBehalf,
        uint256 getId,
        uint256 setId
    );

    event LogSupplyCollateral(
        Id indexed id,
        uint256 assets,
        uint256 getId,
        uint256 setId
    );

    event LogSupplyCollateralOnBehalf(
        Id indexed id,
        uint256 assets,
        address indexed onBehalf,
        uint256 getId,
        uint256 setId
    );

    event LogBorrow(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );

    event LogBorrowOnBehalf(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        address indexed onBehalf,
        address indexed receiver,
        uint256 getId,
        uint256 setId
    );

    event LogWithdraw(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawOnBehalf(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        address indexed onBehalf,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawCollateral(
        Id indexed id,
        uint256 amounts,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawCollateralOnBehalf(
        Id indexed id,
        uint256 amounts,
        address indexed onBehalf,
        address indexed receiver,
        uint256 getId,
        uint256 setId
    );

    event LogRepay(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        uint256 getId,
        uint256 setId
    );

    event LogRepayOnBehalf(
        Id indexed id,
        uint256 amounts,
        uint256 shares,
        address indexed onBehalf,
        uint256 getId,
        uint256 setId
    );
}
