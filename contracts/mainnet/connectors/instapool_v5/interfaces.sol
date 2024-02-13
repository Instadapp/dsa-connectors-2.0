//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface InstaFlashV5Interface {
    function flashLoan(address[] memory tokens, uint256[] memory amts, uint route, bytes memory data, bytes memory extraData) external;
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}
