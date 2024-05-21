//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./helpers.sol";
import "./events.sol";

contract MakerImport is Helpers, Events {
    function transferMakerToFluid(
        uint256 vaultId
    ) public payable returns (string memory _eventName, bytes memory _eventParam) {
        uint256 _vault = getVault(vaultId);
        (bytes32 ilk,) = getVaultData(_vault);

        require(managerContract.owns(_vault) == msg.sender, "not-owner");

        address fluidAddress = fluidWalletFactory.computeWallet(msg.sender);
        managerContract.cdpAllow(_vault, fluidAddress, 1);

        _eventName = "LogTransferToFluid(uint256,bytes32,address)";
        _eventParam = abi.encode(_vault, ilk, fluidAddress);
    }
}

contract ConnectV2FluidMakerImport is MakerImport {
    string public constant name = "Fluid-Maker-Import-v1.0";
}
