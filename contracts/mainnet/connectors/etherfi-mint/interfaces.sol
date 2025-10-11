//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IEtherfiVampire {
    function depositWithERC20(
        address _token,
        uint256 _amount,
        address _referral
    ) external returns (uint256);
}
