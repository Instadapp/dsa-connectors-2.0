// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { DSMath } from "../../common/math.sol";
import { Basic } from "../../common/basic.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { IMakerManager, IFluidWalletFactory } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    IMakerManager internal constant managerContract = IMakerManager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    IFluidWalletFactory internal constant fluidWalletFactory = IFluidWalletFactory(0xd8Ae986159e350B6535539B8A1e488658452f25E);

    function getVaultData(uint vault) internal view returns (bytes32 ilk, address urn) {
        ilk = managerContract.ilks(vault);
        urn = managerContract.urns(vault);
    }

    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "string-empty");
        assembly {
            result := mload(add(str, 32))
        }
    }

    function getVault(uint vault) internal view returns (uint _vault) {
        if (vault == 0) {
            require(managerContract.count(address(this)) > 0, "no-vault-opened");
            _vault = managerContract.last(address(this));
        } else {
            _vault = vault;
        }
    }
}

