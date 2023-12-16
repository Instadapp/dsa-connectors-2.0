//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./helpers.sol";
import "./events.sol";
import {MarketParamsLib} from "./libraries/MarketParamsLib.sol";

abstract contract MorphoBlue is Helpers, Events {
    using MarketParamsLib for MarketParams;

    /**
     * @dev Supply ETH/ERC20 Token for lending.
     * @notice Supplies assets to Morpho Blue for lending.
     * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _assets The amount of assets to supply. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supply(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            address(this),
            _getId,
            Mode.Supply
        );

        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _amt
        );

        uint256 _shares;
        (_assets, _shares) = MORPHO_BLUE.supply(
            _marketParams,
            _amt,
            0,
            address(this),
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogSupplyAssets(bytes32,unit256,unit256,unit256,unit256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _getId,
            _setId
        );
    }

    /**
     * @dev Supply ETH/ERC20 Token for lending.
     * @notice Supplies assets to Morpho Blue for lending.
     * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _assets The amount of assets to supply. (For max: `uint256(-1)`)
     * @param _onBehalf The address that will get the shares.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supplyOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            _onBehalf,
            _getId,
            Mode.Supply
        );

        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _amt
        );

        uint256 _shares;
        (_assets, _shares) = MORPHO_BLUE.supply(
            _marketParams,
            _amt,
            0,
            _onBehalf,
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogSupplyOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @dev Supply ETH/ERC20 Token for lending.
     * @notice Supplies assets for a perfect share amount to Morpho Blue for lending.
     * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _shares The exact amount of shares to mint. (For max: `uint256(-1)`)
     * @param _onBehalf The address that will get the shares.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supplySharesOnBehalf(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt // Shares amount converted to assets
        ) = _performEthToWethSharesConversion(
            _marketParams,
            _shares,
            _onBehalf,
            _getId,
            false
        );

        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _amt
        );

        uint256 _assets;
        (_assets, _shares) = MORPHO_BLUE.supply(
            _marketParams,
            _amt,
            0,
            _onBehalf,
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogSupplyOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @notice Supply ETH/ERC20 Token for collateralization.
     * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _assets The amount of assets to supply. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supplyCollateral(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            address(this),
            _getId,
            Mode.Collateral
        );

        // Approving collateral token
        approve(
            TokenInterface(_marketParams.collateralToken),
            address(MORPHO_BLUE),
            _amt
        );

        MORPHO_BLUE.supplyCollateral(
            _marketParams,
            _amt,
            address(this),
            new bytes(0)
        );

        setUint(_setId, _amt);

        _eventName = "LogSupplyCollateral(bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _assets, _getId, _setId);
    }

    /**
     * @notice Supplies `assets` of collateral on behalf of `onBehalf`.
     * @param _marketParams The market to supply assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _assets The amount of assets to supply. (For max: `uint256(-1)`)
     * @param _onBehalf The address that will get the shares.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function supplyCollateralOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            _onBehalf,
            _getId,
            Mode.Collateral
        );

        // Approving collateral token
        approve(
            TokenInterface(_marketParams.collateralToken),
            address(MORPHO_BLUE),
            _amt
        );

        MORPHO_BLUE.supplyCollateral(
            _marketParams,
            _amt,
            _onBehalf,
            new bytes(0)
        );

        setUint(_setId, _amt);

        _eventName = "LogSupplyCollateralOnBehalf(bytes32,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @notice Handles the collateral withdrawals.
     * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to withdraw assets from.
     * @param _assets The amount of assets to withdraw. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function withdrawCollateral(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        // If amount is max, fetch collateral value from Morpho's contract
        if (_amt == type(uint256).max) {
            Position memory _pos = MORPHO_BLUE.position(_id, address(this));
            _amt = _pos.collateral;
        }

        MORPHO_BLUE.withdrawCollateral(
            _marketParams,
            _amt,
            address(this),
            address(this)
        );

        convertWethToEth(
            _marketParams.collateralToken == ethAddr,
            TokenInterface(wethAddr),
            _amt
        );

        setUint(_setId, _amt);

        _eventName = "LogWithdrawCollateral(bytes32,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _amt, _getId, _setId);
    }

    /**
     * @notice Handles the withdrawal of collateral by a user from a specific market of a specific amount.
     * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to withdraw assets from.
     * @param _assets The amount of assets to withdraw. (For max: `uint256(-1)`)
     * @param _onBehalf The address that already deposited position.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function withdrawCollateralOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        address _receiver,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        // If amount is max, fetch collateral value from Morpho's contract
        if (_amt == type(uint256).max) {
            Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
            _amt = _pos.collateral;
        }

        MORPHO_BLUE.withdrawCollateral(
            _marketParams,
            _amt,
            _onBehalf,
            _receiver
        );

        if (_receiver == address(this))
            convertWethToEth(
                _marketParams.collateralToken == ethAddr,
                TokenInterface(wethAddr),
                _amt
            );

        setUint(_setId, _amt);

        _eventName = "LogWithdrawCollateralOnBehalf(bytes32,uint256,address,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _amt,
            _onBehalf,
            _receiver,
            _getId,
            _setId
        );
    }

    /**
     * @notice Handles the withdrawal of supplied assets.
     * @dev  The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to withdraw assets from.
     * @param _assets The amount of assets to withdraw. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function withdraw(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);
        
        Id _id = _marketParams.id();

        uint256 _shares = 0;

        // Using shares for max amounts to make sure no dust is left on the contract
        if (_amt == type(uint256).max) {
            Position memory _pos = MORPHO_BLUE.position(_id, address(this));
            _shares = _pos.supplyShares;
            _amt = 0;
        }

        // In case of max share amount will be used
        (_assets, _shares) = MORPHO_BLUE.withdraw(
            _marketParams,
            _amt,
            _shares,
            address(this),
            address(this)
        );

        convertWethToEth(
            _marketParams.loanToken == ethAddr,
            TokenInterface(wethAddr),
            _assets
        );

        setUint(_setId, _assets);

        _eventName = "LogWithdraw(bytes32,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _getId,
            _setId
        );
    }

    /**
     * @notice Handles the withdrawal of a specified amount of assets by a user from a specific market.
     * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The parameters of the market.
     * @param _assets The amount of assets the user is withdrawing. (For max: `uint256(-1)`)
     * @param _onBehalf The address who's position to withdraw from.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function withdrawOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        address _receiver,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        uint256 _shares = 0;

        // Using shares for max amounts to make sure no dust is left on the contract
        if (_amt == type(uint256).max) {
            Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
            _shares = _pos.supplyShares;
            _amt = 0;
        }

        (_assets, _shares) = MORPHO_BLUE.withdraw(
            _marketParams,
            _amt,
            _shares,
            _onBehalf,
            _receiver
        );

        if (_receiver == address(this))
            convertWethToEth(
                _marketParams.loanToken == ethAddr,
                TokenInterface(wethAddr),
                _assets
            );

        setUint(_setId, _assets);

        _eventName = "LogWithdrawOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @notice Handles the withdrawal of a specified amount of assets by a user from a specific market.
     * @dev The market to withdraw assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The parameters of the market.
     * @param _shares The amount of shares the user is withdrawing. (For max: `uint256(-1)`)
     * @param _onBehalf The address who's position to withdraw from.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens deposited.
     */
    function withdrawSharesOnBehalf(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        address _receiver,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _shareAmt = getUint(_getId, _shares);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        if (_shareAmt == type(uint256).max) {
            Position memory _pos = MORPHO_BLUE.position(_id, _onBehalf);
            _shareAmt = _pos.supplyShares;
        }

        (uint256 _assets, ) = MORPHO_BLUE.withdraw(
            _marketParams,
            0,
            _shareAmt,
            _onBehalf,
            _receiver
        );

        if (_receiver == address(this))
            convertWethToEth(
                _marketParams.loanToken == ethAddr,
                TokenInterface(wethAddr),
                _assets
            );

        setUint(_setId, _assets);

        _eventName = "LogWithdrawOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shareAmt,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @notice Borrows assets.
     * @dev The market to borrow assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to borrow assets from.
     * @param _assets The amount of assets to borrow.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens borrowed.
     */
    function borrow(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        (, uint256 _shares) = MORPHO_BLUE.borrow(
            _marketParams,
            _amt,
            0,
            address(this),
            address(this)
        );

        convertWethToEth(
            _marketParams.loanToken == ethAddr,
            TokenInterface(wethAddr),
            _amt
        );

        setUint(_setId, _amt);

        _eventName = "LogBorrow(bytes32,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(_id, _amt, _shares, _getId, _setId);
    }

    /**
     * @notice Borrows `assets` on behalf of `onBehalf` to `receiver`.
     * @dev The market to borrow assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams  The market to borrow assets from.
     * @param _assets The amount of assets to borrow.
     * @param _onBehalf The address that will recieve the borrowing assets and own the borrow position.
     * @param _receiver The address that will recieve the borrowed assets.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens borrowed.
     */
    function borrowOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        address _receiver,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(_getId, _assets);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        (, uint256 _shares) = MORPHO_BLUE.borrow(
            _marketParams,
            _amt,
            0,
            _onBehalf,
            _receiver
        );

        if (_receiver == address(this))
            convertWethToEth(
                _marketParams.loanToken == ethAddr,
                TokenInterface(wethAddr),
                _amt
            );

        setUint(_setId, _amt);

        _eventName = "LogBorrowOnBehalf(bytes32,uint256,uint256,address,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _amt,
            _shares,
            _onBehalf,
            _receiver,
            _getId,
            _setId
        );
    }

    /**
     * @notice Borrows `shares` on behalf of `onBehalf` to `receiver`.
     * @dev The market to borrow assets from. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to borrow assets from.
     * @param _shares The amount of shares to mint.
     * @param _onBehalf The address that will own the borrow position.
     * @param _receiver The address that will recieve the borrowed assets.
     * @param _getId ID to retrieve shares amt.
     * @param _setId ID stores the amount of tokens borrowed.
     */
    function borrowOnBehalfShares(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        address _receiver,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _shareAmt = getUint(_getId, _shares);

        _marketParams = updateTokenAddresses(_marketParams);

        Id _id = _marketParams.id();

        (uint256 _assets, ) = MORPHO_BLUE.borrow(
            _marketParams,
            0,
            _shareAmt,
            _onBehalf,
            _receiver
        );

        if (_receiver == address(this))
            convertWethToEth(
                _marketParams.loanToken == ethAddr,
                TokenInterface(wethAddr),
                _assets
            );

        setUint(_setId, _assets);

        _eventName = "LogBorrowOnBehalf(bytes32,uint256,uint256,address,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shareAmt,
            _onBehalf,
            _receiver,
            _getId,
            _setId
        );
    }

    /**
     * @notice Repay assets.
     * @dev The market to repay assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to repay assets to.
     * @param _assets The amount of assets to repay. (For max: `uint256(-1)`)
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens repaid.
     */
    function repay(
        MarketParams memory _marketParams,
        uint256 _assets,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt // Assets final amount to repay
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            address(this),
            _getId,
            Mode.Repay
        );

        // Approving loan token for repaying
        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _amt
        );

        uint256 _shares;
        (_assets, _shares) = MORPHO_BLUE.repay(
            _marketParams,
            _amt,
            0,
            address(this),
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogRepay(bytes32,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _getId,
            _setId
        );
    }

    /**
     * @notice Repays assets on behalf.
     * @dev The market to repay assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to repay assets to.
     * @param _assets The amount of assets to repay. (For max: `uint256(-1)`)
     * @param _onBehalf The address whose loan will be repaid.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens repaid.
     */
    function repayOnBehalf(
        MarketParams memory _marketParams,
        uint256 _assets,
        address _onBehalf,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _amt // Assets final amount to repay
        ) = _performEthToWethConversion(
            _marketParams,
            _assets,
            _onBehalf,
            _getId,
            Mode.Repay
        );

        // Approving loan token for repaying
        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _amt
        );

        uint256 _shares;
        (_assets, _shares) = MORPHO_BLUE.repay(
            _marketParams,
            _amt,
            0,
            _onBehalf,
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogRepayOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _onBehalf,
            _getId,
            _setId
        );
    }

    /**
     * @notice Repays shares on behalf.
     * @dev The market to repay assets to. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param _marketParams The market to repay assets to.
     * @param _shares The amount of shares to burn. (For max: `uint256(-1)`)
     * @param _onBehalf The address whose loan will be repaid.
     * @param _getId ID to retrieve amt.
     * @param _setId ID stores the amount of tokens repaid.
     */
    function repayOnBehalfShares(
        MarketParams memory _marketParams,
        uint256 _shares,
        address _onBehalf,
        uint256 _getId,
        uint256 _setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _assetsAmt;
        Id _id;
        (
            _id,
            _marketParams, // Updated token contracts in case of Eth
            _assetsAmt // Shares amount converted to assets
        ) = _performEthToWethSharesConversion(
            _marketParams,
            _shares,
            _onBehalf,
            _getId,
            true
        );

        approve(
            TokenInterface(_marketParams.loanToken),
            address(MORPHO_BLUE),
            _assetsAmt
        );

        (uint256 _assets, ) = MORPHO_BLUE.repay(
            _marketParams,
            _assetsAmt,
            0,
            _onBehalf,
            new bytes(0)
        );

        setUint(_setId, _assets);

        _eventName = "LogRepayOnBehalf(bytes32,uint256,uint256,address,uint256,uint256)";
        _eventParam = abi.encode(
            _id,
            _assets,
            _shares,
            _onBehalf,
            _getId,
            _setId
        );
    }
}

contract ConnectV2MorphoBlue is MorphoBlue {
    string public constant name = "Morpho-Blue-v1.0";
}
