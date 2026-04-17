# Venus Core BSC Connector Design Spec

## Overview

A DSA connector for Venus Core Pool (v4) on BSC chain, providing deposit, borrow, repay, withdraw with onBehalf functionality, plus collateral management.

- **Connector name:** `ConnectV2VenusCoreBSC`
- **Name string:** `"VenusCore-BSC-v1.0"`
- **Target:** Venus v4 Core Pool on BSC mainnet
- **Comptroller:** `0xfD36E2c2a6789Db23113685031d7F16329158384`

## File Structure

```
contracts/bsc/connectors/venus-v4/
├── interface.sol    — VTokenInterface, ComptrollerInterface
├── helpers.sol      — Constants, _enterMarket, _isMarketEntered
├── events.sol       — 11 event definitions
└── main.sol         — VenusResolver (11 functions) + ConnectV2VenusCoreBSC
```

Inheritance chain:
```
Stores → Basic → DSMath → Helpers → Events → VenusResolver → ConnectV2VenusCoreBSC
```

## Input Pattern

Every function accepts `(address token, address vToken, ...)` where:
- `token` = underlying token address, or `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` for native BNB
- `vToken` = the Venus market contract address (e.g., vUSDT, vBNB)

This avoids on-chain mapping lookups while staying consistent with how other connectors accept underlying token addresses.

## Native BNB Handling

Venus Core Pool's vBNB market accepts native BNB as `msg.value` (no WBNB wrapping needed):
- **Deposit/Repay:** Send BNB as value — `VToken.mint{value: amt}()` / `VToken.repayBorrow{value: amt}()`
- **Withdraw/Borrow:** Venus sends native BNB back to caller — no unwrapping needed
- **ERC20 path:** Standard `approve` then call pattern

The `isEth` check (`token == bnbAddr`) determines which path to take.

## Interface Definitions (`interface.sol`)

```solidity
interface VTokenInterface {
    function mint(uint256 mintAmount) external returns (uint256);
    function mintBehalf(address minter, uint256 mintAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function borrowBehalf(address borrower, uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemBehalf(address redeemer, uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function redeemUnderlyingBehalf(address redeemer, uint256 redeemAmount) external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function underlying() external view returns (address);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);
    function exitMarket(address vToken) external returns (uint256);
    function getAssetsIn(address account) external view returns (address[] memory);
}
```

All VToken functions return `uint256` error codes (0 = success). The connector must check return values and revert on non-zero.

## Helpers (`helpers.sol`)

```solidity
abstract contract Helpers is DSMath, Basic {
    ComptrollerInterface internal constant comptroller =
        ComptrollerInterface(0xfD36E2c2a6789Db23113685031d7F16329158384);

    function _enterMarket(address vToken) internal {
        address[] memory markets = new address[](1);
        markets[0] = vToken;
        comptroller.enterMarkets(markets);
    }

    function _isMarketEntered(address vToken) internal view returns (bool) {
        address[] memory assets = comptroller.getAssetsIn(address(this));
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i] == vToken) return true;
        }
        return false;
    }
}
```

## Events (`events.sol`)

11 events:

| Event | Fields |
|-------|--------|
| `LogDeposit` | token (indexed), vToken (indexed), tokenAmt, getId, setId |
| `LogDepositWithoutCollateral` | token (indexed), vToken (indexed), tokenAmt, getId, setId |
| `LogDepositOnBehalfOf` | token (indexed), vToken (indexed), tokenAmt, onBehalfOf, getId, setId |
| `LogWithdraw` | token (indexed), vToken (indexed), tokenAmt, getId, setId |
| `LogWithdrawOnBehalfOf` | token (indexed), vToken (indexed), tokenAmt, onBehalfOf, getId, setId |
| `LogBorrow` | token (indexed), vToken (indexed), tokenAmt, getId, setId |
| `LogBorrowOnBehalfOf` | token (indexed), vToken (indexed), tokenAmt, onBehalfOf, getId, setId |
| `LogRepay` | token (indexed), vToken (indexed), tokenAmt, getId, setId |
| `LogRepayOnBehalfOf` | token (indexed), vToken (indexed), tokenAmt, onBehalfOf, getId, setId |
| `LogEnableCollateral` | vTokens |
| `LogDisableCollateral` | vTokens |

## Function Specifications (11 total)

All functions are `external payable` and return `(string memory _eventName, bytes memory _eventParam)`.

### Deposit Functions (3)

#### `deposit(address token, address vToken, uint256 amt, uint256 getId, uint256 setId)`
1. Resolve `amt` via `getUint(getId, amt)`
2. If BNB: max = `address(this).balance`, call `VToken.mint{value: _amt}(_amt)`
3. If ERC20: max = `tokenContract.balanceOf(address(this))`, `approve` vToken, call `VToken.mint(_amt)`
4. Require return == 0
5. If market not entered: call `_enterMarket(vToken)`
6. `setUint(setId, _amt)`, emit `LogDeposit`

#### `depositWithoutCollateral(address token, address vToken, uint256 amt, uint256 getId, uint256 setId)`
- Same as `deposit` but skips `enterMarkets` step

#### `depositOnBehalfOf(address token, address vToken, uint256 amt, address onBehalfOf, uint256 getId, uint256 setId)`
1. Resolve `amt`, handle max
2. If BNB: call `VToken.mintBehalf{value: _amt}(onBehalfOf, _amt)`
3. If ERC20: `approve` vToken, call `VToken.mintBehalf(onBehalfOf, _amt)`
4. Require return == 0
5. `setUint(setId, _amt)`, emit `LogDepositOnBehalfOf`

Note: Does NOT auto-enter market for `onBehalfOf` — the beneficiary must manage their own collateral settings.

### Withdraw Functions (2)

#### `withdraw(address token, address vToken, uint256 amt, uint256 getId, uint256 setId)`
1. Resolve `amt` via `getUint(getId, amt)`
2. Record initial balance (native BNB or ERC20)
3. If max (`type(uint256).max`): call `VToken.redeem(VToken.balanceOf(address(this)))`
4. Otherwise: call `VToken.redeemUnderlying(_amt)`
5. Require return == 0
6. Calculate actual withdrawn via balance diff
7. `setUint(setId, actualAmt)`, emit `LogWithdraw`

#### `withdrawOnBehalfOf(address token, address vToken, uint256 amt, address onBehalfOf, uint256 getId, uint256 setId)`
1. Resolve `amt`
2. Record initial balance
3. If max: call `VToken.redeemBehalf(onBehalfOf, VToken.balanceOf(onBehalfOf))`
4. Otherwise: call `VToken.redeemUnderlyingBehalf(onBehalfOf, _amt)`
5. Require return == 0
6. Calculate actual withdrawn via balance diff
7. `setUint(setId, actualAmt)`, emit `LogWithdrawOnBehalfOf`

### Borrow Functions (2)

#### `borrow(address token, address vToken, uint256 amt, uint256 getId, uint256 setId)`
1. Resolve `amt` via `getUint(getId, amt)`
2. Call `VToken.borrow(_amt)`
3. Require return == 0
4. `setUint(setId, _amt)`, emit `LogBorrow`

#### `borrowOnBehalfOf(address token, address vToken, uint256 amt, address onBehalfOf, uint256 getId, uint256 setId)`
1. Resolve `amt`
2. Call `VToken.borrowBehalf(onBehalfOf, _amt)` — debt assigned to `onBehalfOf`, tokens to `address(this)`
3. Require return == 0
4. `setUint(setId, _amt)`, emit `LogBorrowOnBehalfOf`

### Repay Functions (2)

#### `repay(address token, address vToken, uint256 amt, uint256 getId, uint256 setId)`
1. Resolve `amt` via `getUint(getId, amt)`
2. If max: `_amt = min(DSA balance, VToken.borrowBalanceCurrent(address(this)))`
3. If BNB: call `VToken.repayBorrow{value: _amt}()`
4. If ERC20: `approve` vToken, call `VToken.repayBorrow(_amt)`
5. Require return == 0
6. `setUint(setId, _amt)`, emit `LogRepay`

#### `repayOnBehalfOf(address token, address vToken, uint256 amt, address onBehalfOf, uint256 getId, uint256 setId)`
1. Resolve `amt`
2. If max: `_amt = min(DSA balance, VToken.borrowBalanceCurrent(onBehalfOf))`
3. If BNB: call `VToken.repayBorrowBehalf{value: _amt}(onBehalfOf)`
4. If ERC20: `approve` vToken, call `VToken.repayBorrowBehalf(onBehalfOf, _amt)`
5. Require return == 0
6. `setUint(setId, _amt)`, emit `LogRepayOnBehalfOf`

### Collateral Functions (2)

#### `enableCollateral(address[] calldata vTokens)`
1. Require `vTokens.length > 0`
2. Call `comptroller.enterMarkets(vTokens)`
3. Emit `LogEnableCollateral`

#### `disableCollateral(address[] calldata vTokens)`
1. Require `vTokens.length > 0`
2. Loop: call `comptroller.exitMarket(vTokens[i])` for each
3. Emit `LogDisableCollateral`

## Error Handling

Venus VToken functions return error codes (Compound-style) instead of reverting:
- `0` = success
- Non-zero = failure

Every VToken call must be followed by: `require(returnCode == 0, "venus-[operation]-failed");`

## Max Amount Convention

Following the existing codebase convention:
- `type(uint256).max` signals "use maximum available"
- **Deposit max:** full DSA balance of the underlying token (or native BNB balance)
- **Withdraw max:** full vToken balance, use `redeem` (by vToken amount) instead of `redeemUnderlying`
- **Repay max:** `min(DSA balance, outstanding debt via borrowBalanceCurrent)`
- **Borrow:** no max handling (user must specify exact amount)
