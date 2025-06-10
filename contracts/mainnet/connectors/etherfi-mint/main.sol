//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Helpers} from "./helpers.sol";
import {Events} from "./events.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract EtherfiMintConnector is Helpers, Events {
    function mintEethFromStEth(
        uint256 depositAmount_
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
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

        _eventName = "LogMintEtherfi(address,uint256)";
        _eventParam = abi.encode(depositAmount_, eEthAmount_);
    }
}

contract ConnectV2EtherfiMint is EtherfiMintConnector {
    string public name = "Etherfi-Mint-v1.0";
}
