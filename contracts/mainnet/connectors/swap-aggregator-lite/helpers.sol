//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {InstaConnectors} from "../../common/interfaces.sol";
import {TokenInterface} from "../../common/interfaces.sol";

contract SwapHelpers {
    /**
     * @dev Instadapp Connectors Registry
     */
    InstaConnectors internal constant instaConnectors =
        InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

    /**
     * @dev Swap using the dex aggregators.
     * @param connectors_ name of the connectors in preference order.
     * @param datas_ data for the swap cast.
     */
    function _swap(
        string[] memory connectors_,
        bytes[] memory datas_
    )
        internal
        returns (bool success, bytes memory returnData, string memory connector)
    {
        uint256 length_ = connectors_.length;
        require(length_ > 0, "zero-length-not-allowed");
        require(datas_.length == length_, "calldata-length-invalid");

        (bool isOk, address[] memory connectors) = instaConnectors.isConnectors(
            connectors_
        );
        require(isOk, "connector-names-invalid");

        for (uint256 i = 0; i < length_; i++) {
            (success, returnData) = connectors[i].delegatecall(datas_[i]);
            if (success) {
                connector = connectors_[i];
                break;
            }
        }
    }

    /**
     * @dev Get the amount in USD (1e6 decimals).
     * @param tokenAddress_ address of the token.
     * @param amount_ amount of the token.
     * @param exchangeRate_ exchange rate of the token.
     */
    function _getAmountInUsd(
        address tokenAddress_,
        uint256 amount_,
        uint256 exchangeRate_
    ) internal view returns (uint256 amountInUsd_) {
        uint256 tokenDecimals_ = TokenInterface(tokenAddress_).decimals();
        amountInUsd_ =
            (amount_ * exchangeRate_) /
            10 ** (2 * tokenDecimals_ - 6);
    }
}
