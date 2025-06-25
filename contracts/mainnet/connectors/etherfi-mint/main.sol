//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract EtherfiMintConnector is Helpers, Events {
    error EtherfiMintConnector__AmountReceivedIsLess();

    function mintEethFromStEth(
        uint256 depositAmount_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        if (depositAmount_ == type(uint256).max) {
            depositAmount_ = address(this).balance;
        }

        // Approve the Etherfi Vampire contract to spend the specified amount of stETH
        TokenInterface(STETH_ADDRESS).approve(
            address(ETHERFI_VAMPIRE_CONTRACT),
            depositAmount_
        );

        // Deposit stETH into the Etherfi Vampire contract and Mint eETH
        uint256 eEthAmount_ = ETHERFI_VAMPIRE_CONTRACT.depositWithERC20(
            STETH_ADDRESS,
            depositAmount_,
            REFERRAL_ADDRESS
        );

        // In reality the difference between depositAmount_ and eEthAmount_ is 1 Wei,
        // but keeping a buffer of 1 Gwei
        if (eEthAmount_ < (depositAmount_ - 1e9)) {
            revert EtherfiMintConnector__AmountReceivedIsLess();
        }

        _eventName = "LogMintEtherfi(address,uint256)";
        _eventParam = abi.encode(depositAmount_, eEthAmount_);
    }
}

contract ConnectV2EtherfiMint is EtherfiMintConnector {
    string public name = "Etherfi-Mint-v1.0";
}
