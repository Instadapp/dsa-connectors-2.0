//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events {
    event LogFlashBorrow(address token, uint256 tokenAmt);
    event LogFlashPayback(address token, uint256 tokenAmt);

    event LogFlashMultiBorrow(address[] token, uint256[] tokenAmts);
    event LogFlashMultiPayback(address[] token, uint256[] tokenAmts);
}
