import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2FluidDexV2MMPolygon__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { ethers } from "hardhat";
import type { Signer, Contract, BigNumberish } from "ethers";
import { BigNumber } from "ethers";

// Fluid Money Market on Polygon (audited build, live since block 96039366 / tx 0xffb99e8d...)
describe("Fluid DEX v2 Money Market", function () {
  const connectorName = "FLUID-DEX-V2-MM-A";
  let connector: any;

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;

  const MM = "0x2536CbF2F657F153A86aCF8435293c60A23D32bf";
  const DEX_V2_RESOLVER = "0xA206dd5502A09Ab106dfc95f9cd8C378CF497eAf";

  const USDC = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359";
  const USDT = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F";
  const POL = constants.native_address;
  const ZERO = constants.address_zero;

  // token indices in the Money Market, listing order of the go-live tx
  const I_USDC = 1;
  const I_USDT = 2;
  const I_POL = 4;

  // Aave v3 aTokens, used as token holders
  const usdcHolder = "0xA4D94019934D8333Ef880ABFFbF2FDd611C762BD";
  const usdtHolder = "0x6ab707Aca953eDAeFBc4fD23bA73294241490620";

  const MAX_INT = ethers.constants.MaxInt256;
  const MIN_INT = ethers.constants.MinInt256;

  const setIdNft = "83478237";
  const setIdCol0 = "83478238";
  const setIdDebt0 = "83478239";
  const noIds = ["0", "0", "0", "0", "0", "0"];

  const erc20Abi = [
    "function balanceOf(address) view returns (uint256)",
    "function transfer(address to, uint256 value) returns (bool)",
    "function allowance(address owner, address spender) view returns (uint256)"
  ];
  const mmAbi = [
    "function ownerOf(uint256) view returns (address)",
    "function balanceOf(address) view returns (uint256)",
    "function getHfInfo(uint256 nftId_, bool isOperate_) returns ((uint256 hf, uint256 collateralValue, uint256 debtValue, uint256 normalizedCollateralValue, uint256 minNormalizedCollateralValue))",
    "event Transfer(address indexed from, address indexed to, uint256 indexed id)",
    "event LogOperate(uint256 nftId, uint256 positionIndex, address user, bytes actionData)"
  ];
  const usdc = new ethers.Contract(USDC, erc20Abi, ethers.provider);
  const usdt = new ethers.Contract(USDT, erc20Abi, ethers.provider);
  const mm = new ethers.Contract(MM, mmAbi, ethers.provider);

  const abiCoder = ethers.utils.defaultAbiCoder;
  const encodeCreateSupply = (tokenIndex: number, amount: BigNumberish) =>
    abiCoder.encode(["uint256", "uint256", "uint256"], [1, tokenIndex, amount]);
  const encodeCreateBorrow = (tokenIndex: number, amount: BigNumberish, to: string) =>
    abiCoder.encode(["uint256", "uint256", "uint256", "address"], [2, tokenIndex, amount, to]);
  const encodeToken = (amount: BigNumberish, to: string) => abiCoder.encode(["int256", "address"], [amount, to]);
  const encodeCreateDex = (positionType: number, params: any) =>
    abiCoder.encode(
      [
        "uint256",
        "tuple(uint256 token0Index, uint256 token1Index, uint24 tickSpacing, uint24 fee, address controller, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1, uint256 amount0Min, uint256 amount1Min, address to)"
      ],
      [positionType, params]
    );
  const encodeDex = (amount0: BigNumberish, amount1: BigNumberish, to: string) =>
    abiCoder.encode(["int256", "int256", "uint256", "uint256", "address"], [amount0, amount1, 0, 0, to]);

  // USDC/USDT D3 + D4 pools: fee 0.01 %, tick spacing 1
  const stableKey = { token0: USDC, token1: USDT, fee: 100, tickSpacing: 1, controller: ZERO };

  async function currentTick(dexType: number, key: any): Promise<number> {
    const iface = new ethers.utils.Interface([
      "function getDexPoolState(uint256 dexType_, (address token0, address token1, uint24 fee, uint24 tickSpacing, address controller) dexKey_) view returns (bytes)"
    ]);
    const data = iface.encodeFunctionData("getDexPoolState", [dexType, key]);
    const raw = await ethers.provider.call({ to: DEX_V2_RESOLVER, data });
    // DexPoolState is static: dexId, dexPriceParsed, dexVariablesPacked, dexVariables2Packed, currentTick, ...
    return BigNumber.from("0x" + raw.slice(2 + 64 * 4, 2 + 64 * 5)).fromTwos(256).toNumber();
  }

  async function cast(spells: any[], value: BigNumberish = 0) {
    const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress(), { value });
    return await tx.wait();
  }

  function mintedNftId(receipt: any): BigNumber {
    const topic = mm.interface.getEventTopic("Transfer");
    const log = receipt.logs.find(
      (l: any) => l.address.toLowerCase() === MM.toLowerCase() && l.topics[0] === topic && BigNumber.from(l.topics[1]).isZero()
    );
    expect(log, "Transfer from zero address").to.not.be.undefined;
    return BigNumber.from(log.topics[3]);
  }

  async function hfInfo(nftId: BigNumberish) {
    return await mm.callStatic.getHfInfo(nftId, true);
  }

  function operateSpell(positionType: number, nftId: BigNumberish, index: BigNumberish, actionData: string, tokens: [string, string], approvals: [BigNumberish, BigNumberish]) {
    return {
      connector: connectorName,
      method: "operate",
      args: [
        positionType,
        nftId,
        index,
        actionData,
        { token0Address: tokens[0], token1Address: tokens[1] },
        { approveAmount0: approvals[0], approveAmount1: approvals[1] }
      ]
    };
  }

  function operateWithIdsSpell(positionType: number, nftId: BigNumberish, index: BigNumberish, actionData: string, tokens: [string, string], paybackApprovals: [BigNumberish, BigNumberish], getIds: string[], setIds: string[]) {
    return {
      connector: connectorName,
      method: "operateWithIds",
      args: [
        positionType,
        nftId,
        index,
        actionData,
        { token0Address: tokens[0], token1Address: tokens[1] },
        { approveAmount0: paybackApprovals[0], approveAmount1: paybackApprovals[1] },
        getIds,
        setIds
      ]
    };
  }

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 96041200
          }
        }
      ]
    });

    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2, masterSigner);

    // FLUID-DEX-V2-MM-A already points at the test-MM connector at this block; Team MS1 repoints it with
    // updateConnectors, so the test does the same instead of addConnectors
    connector = await new ConnectV2FluidDexV2MMPolygon__factory(masterSigner).deploy();
    await instaConnectorsV2.connect(masterSigner).updateConnectors([connectorName], [connector.address]);
    addresses.connectors[connectorName] = connector.address;
    abis.connectors[connectorName] = ConnectV2FluidDexV2MMPolygon__factory.abi;
    console.log("Connector address", connector.address);
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(await connector.name()).to.equal("Fluid-Dex-v2-MM-v1.1");
    expect(await instaConnectorsV2.connectors(connectorName)).to.equal(connector.address);
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit POL, USDC and USDT into DSA wallet", async function () {
      await hre.network.provider.send("hardhat_setBalance", [dsaWallet0.address, parseEther("50000").toHexString()]);

      for (const [holder, token, amount] of [
        [usdcHolder, usdc, parseUnits("10000", 6)],
        [usdtHolder, usdt, parseUnits("10000", 6)]
      ] as const) {
        await hre.network.provider.send("hardhat_setBalance", [holder, parseEther("10").toHexString()]);
        await hre.network.provider.request({ method: "hardhat_impersonateAccount", params: [holder] });
        await token.connect(await ethers.getSigner(holder)).transfer(dsaWallet0.address, amount);
      }

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(parseEther("50000"));
      expect(await usdc.balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("10000", 6));
      expect(await usdt.balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("10000", 6));
    });
  });

  // token supply caps on the live market: USDC 4,000, USDT 4,000, WETH 1.5, POL 40,000
  describe("Normal positions: USDC collateral, USDT debt", function () {
    let nftId: BigNumber;

    it("should open a new NFT with 2,000 USDC collateral (operate)", async function () {
      const amount = parseUnits("2000", 6);
      const before = await usdc.balanceOf(dsaWallet0.address);

      const receipt = await cast([operateSpell(1, 0, 0, encodeCreateSupply(I_USDC, amount), [USDC, ZERO], [amount, 0])]);
      nftId = mintedNftId(receipt);

      expect(await mm.ownerOf(nftId)).to.equal(dsaWallet0.address);
      expect(before.sub(await usdc.balanceOf(dsaWallet0.address))).to.equal(amount);
      expect((await hfInfo(nftId)).collateralValue).to.be.gt(0);
    });

    it("should supply 500 USDC more on position 1 (operateWithIds)", async function () {
      const amount = parseUnits("500", 6);
      const before = await usdc.balanceOf(dsaWallet0.address);

      await cast([operateWithIdsSpell(1, nftId, 1, encodeToken(amount, ZERO), [USDC, ZERO], [0, 0], noIds, [setIdNft, "0", setIdCol0, "0", "0", "0"])]);

      // operateWithIds approves the amount and operates amount - 1
      expect(before.sub(await usdc.balanceOf(dsaWallet0.address))).to.equal(amount.sub(1));
      expect(await usdc.allowance(dsaWallet0.address, MM)).to.equal(0);
    });

    it("should borrow 1,000 USDT into the DSA (operate, new position)", async function () {
      const amount = parseUnits("1000", 6);
      const before = await usdt.balanceOf(dsaWallet0.address);

      await cast([operateSpell(2, nftId, 0, encodeCreateBorrow(I_USDT, amount, dsaWallet0.address), [USDT, ZERO], [0, 0])]);

      expect((await usdt.balanceOf(dsaWallet0.address)).sub(before)).to.equal(amount);
      expect((await hfInfo(nftId)).debtValue).to.be.gt(0);
    });

    it("should pay back the whole USDT debt with type(int256).min (operateWithIds)", async function () {
      const before = await usdt.balanceOf(dsaWallet0.address);
      const approval = parseUnits("1100", 6); // debt plus a margin; the Money Market pulls only the debt

      await cast([operateWithIdsSpell(2, nftId, 2, encodeToken(MIN_INT, ZERO), [USDT, ZERO], [approval, 0], noIds, [setIdNft, "0", "0", "0", setIdDebt0, "0"])]);

      const paid = before.sub(await usdt.balanceOf(dsaWallet0.address));
      expect(paid).to.be.gte(parseUnits("1000", 6));
      expect(paid).to.be.lt(parseUnits("1001", 6));
      expect((await hfInfo(nftId)).debtValue).to.equal(0);
      expect(await usdt.allowance(dsaWallet0.address, MM)).to.equal(0);
    });

    it("should withdraw 1,000 USDC (operate)", async function () {
      const amount = parseUnits("1000", 6);
      const before = await usdc.balanceOf(dsaWallet0.address);

      await cast([operateSpell(1, nftId, 1, encodeToken(amount.mul(-1), dsaWallet0.address), [USDC, ZERO], [0, 0])]);

      expect((await usdc.balanceOf(dsaWallet0.address)).sub(before)).to.equal(amount);
    });

    it("should withdraw the rest of the USDC with type(int256).min (operateWithIds)", async function () {
      const before = await usdc.balanceOf(dsaWallet0.address);

      await cast([operateWithIdsSpell(1, nftId, 1, encodeToken(MIN_INT, ZERO), [USDC, ZERO], [0, 0], noIds, noIds)]);

      // 2,000 + 499.999999 supplied, 1,000 withdrawn: ~1,500 left, less 1-2 raw of rounding
      const got = (await usdc.balanceOf(dsaWallet0.address)).sub(before);
      expect(got).to.be.gt(parseUnits("1499", 6));
      expect(got).to.be.lt(parseUnits("1501", 6));
      expect((await hfInfo(nftId)).collateralValue).to.equal(0);
    });

    describe("native POL on the same NFT", function () {
      it("should supply 20,000 POL as a new position on the existing NFT (operateWithIds, positionIndex 0)", async function () {
        const amount = parseEther("20000");
        const before = await ethers.provider.getBalance(dsaWallet0.address);

        await cast([operateWithIdsSpell(1, nftId, 0, encodeCreateSupply(I_POL, amount), [POL, ZERO], [0, 0], noIds, noIds)]);

        expect(before.sub(await ethers.provider.getBalance(dsaWallet0.address))).to.equal(amount.sub(1));
        expect((await hfInfo(nftId)).collateralValue).to.be.gt(0);
      });

      it("should borrow 5,000 POL into the DSA (operate)", async function () {
        const amount = parseEther("5000");
        const before = await ethers.provider.getBalance(dsaWallet0.address);

        await cast([operateSpell(2, nftId, 0, encodeCreateBorrow(I_POL, amount, dsaWallet0.address), [POL, ZERO], [0, 0])]);

        expect((await ethers.provider.getBalance(dsaWallet0.address)).sub(before)).to.equal(amount);
      });

      // Same Money Market rounding as below: the full native payback resolves above what Liquidity holds for the
      // Money Market and panics (0x11) in Liquidity. The DSA calling MM.operate directly gets the same panic.
      it("full POL payback with type(int256).min currently panics in Liquidity (Money Market rounding)", async function () {
        const value = parseEther("5100");
        await expect(cast([operateWithIdsSpell(2, nftId, 2, encodeToken(MIN_INT, ZERO), [POL, ZERO], [value, 0], noIds, noIds)])).to.be.revertedWithPanic(0x11);

        await hre.network.provider.request({ method: "hardhat_impersonateAccount", params: [dsaWallet0.address] });
        const dsaSigner = await ethers.getSigner(dsaWallet0.address);
        const mmOperate = new ethers.Contract(MM, ["function operate(uint256,uint256,bytes) payable returns (uint256,uint256,bytes)"], dsaSigner);
        await expect(mmOperate.operate(nftId, 2, encodeToken(MIN_INT, ZERO), { value })).to.be.revertedWithPanic(0x11);
      });

      it("should pay back 5,000 POL with native value (operateWithIds)", async function () {
        const amount = parseEther("5000");
        const before = await ethers.provider.getBalance(dsaWallet0.address);
        const debtBefore = (await hfInfo(nftId)).debtValue;

        await cast([operateWithIdsSpell(2, nftId, 2, encodeToken(amount.mul(-1), ZERO), [POL, ZERO], [0, 0], noIds, noIds)]);

        // amount - 1 is paid back, the 1 wei of unspent value is refunded by the Money Market
        expect(before.sub(await ethers.provider.getBalance(dsaWallet0.address))).to.equal(amount.sub(1));
        expect((await hfInfo(nftId)).debtValue).to.be.lt(debtBefore.div(1000));
      });

      it("should withdraw 18,000 POL (operate)", async function () {
        const amount = parseEther("18000"); // the rest stays above minNormalizedCollateralValue for the dust debt
        const before = await ethers.provider.getBalance(dsaWallet0.address);

        await cast([operateSpell(1, nftId, 1, encodeToken(amount.mul(-1), dsaWallet0.address), [POL, ZERO], [0, 0])]);

        expect((await ethers.provider.getBalance(dsaWallet0.address)).sub(before)).to.equal(amount);
      });
    });
  });

  describe("Emode 1 (USDC/USDT)", function () {
    let nftId: BigNumber;
    const extra = parseUnits("500", 6);

    it("should supply 3,000 USDC and borrow 2,000 USDT in emode 0", async function () {
      const receipt = await cast([operateSpell(1, 0, 0, encodeCreateSupply(I_USDC, parseUnits("3000", 6)), [USDC, ZERO], [parseUnits("3000", 6), 0])]);
      nftId = mintedNftId(receipt);
      await cast([operateSpell(2, nftId, 0, encodeCreateBorrow(I_USDT, parseUnits("2000", 6), dsaWallet0.address), [USDT, ZERO], [0, 0])]);
      expect((await hfInfo(nftId)).debtValue).to.be.gt(0);
    });

    it("should not borrow 500 USDT more at CF 70 %", async function () {
      await expect(cast([operateSpell(2, nftId, 2, encodeToken(extra, dsaWallet0.address), [USDT, ZERO], [0, 0])])).to.be.reverted;
    });

    it("should change to emode 1 and borrow the 500 USDT", async function () {
      const hf0 = (await hfInfo(nftId)).hf;
      await cast([{ connector: connectorName, method: "changeEMode", args: [nftId, 1] }]);
      expect((await hfInfo(nftId)).hf).to.be.gt(hf0);

      const before = await usdt.balanceOf(dsaWallet0.address);
      await cast([operateSpell(2, nftId, 2, encodeToken(extra, dsaWallet0.address), [USDT, ZERO], [0, 0])]);
      expect((await usdt.balanceOf(dsaWallet0.address)).sub(before)).to.equal(extra);
    });

    it("should pay back 400 USDT (operateWithIds)", async function () {
      const amount = parseUnits("400", 6);
      const before = await usdt.balanceOf(dsaWallet0.address);
      const debtBefore = (await hfInfo(nftId)).debtValue;

      await cast([operateWithIdsSpell(2, nftId, 2, encodeToken(amount.mul(-1), ZERO), [USDT, ZERO], [0, 0], noIds, noIds)]);

      expect(before.sub(await usdt.balanceOf(dsaWallet0.address))).to.equal(amount.sub(1));
      expect((await hfInfo(nftId)).debtValue).to.be.lt(debtBefore);
    });

    // Money Market behaviour, not the connector's: after a partial payback the full payback (type(int256).min)
    // resolves to a figure a few raw above what Liquidity holds for the Money Market and Liquidity's checked
    // subtraction panics (0x11). Reproduced with a direct MM.operate on the fork; same revert through both
    // connector functions.
    it("full payback after a partial payback currently panics in Liquidity (Money Market rounding)", async function () {
      await expect(cast([operateSpell(2, nftId, 2, encodeToken(MIN_INT, ZERO), [USDT, ZERO], [parseUnits("2200", 6), 0])])).to.be.revertedWithPanic(0x11);
      await expect(cast([operateWithIdsSpell(2, nftId, 2, encodeToken(MIN_INT, ZERO), [USDT, ZERO], [parseUnits("2200", 6), 0], noIds, noIds)])).to.be.revertedWithPanic(0x11);
    });
  });

  describe("Spell composition through InstaMemory", function () {
    it("should mint, store the NFT id and borrow against it in one cast (operateWithIds)", async function () {
      const supply = parseUnits("800", 6);
      const borrow = parseUnits("300", 6);
      const usdtBefore = await usdt.balanceOf(dsaWallet0.address);
      const nftsBefore = await mm.balanceOf(dsaWallet0.address);

      const receipt = await cast([
        operateWithIdsSpell(1, 0, 0, encodeCreateSupply(I_USDC, supply), [USDC, ZERO], [0, 0], noIds, [setIdNft, "0", "0", "0", "0", "0"]),
        operateWithIdsSpell(2, 0, 0, encodeCreateBorrow(I_USDT, borrow, ZERO), [USDT, ZERO], [0, 0], [setIdNft, "0", "0", "0", "0", "0"], noIds)
      ]);
      const nftId = mintedNftId(receipt);

      expect((await mm.balanceOf(dsaWallet0.address)).sub(nftsBefore)).to.equal(1);
      expect((await usdt.balanceOf(dsaWallet0.address)).sub(usdtBefore)).to.equal(borrow);
      expect((await hfInfo(nftId)).debtValue).to.be.gt(0);
    });
  });

  describe("D3 collateral and D4 debt on the USDC/USDT pools", function () {
    let nftId: BigNumber;
    const d3Amount = parseUnits("1000", 6);
    const d4Amount = parseUnits("200", 6);

    it("should open a D3 USDC/USDT position (operate, new NFT)", async function () {
      const tick = await currentTick(3, stableKey);
      const usdcBefore = await usdc.balanceOf(dsaWallet0.address);
      const usdtBefore = await usdt.balanceOf(dsaWallet0.address);

      const params = {
        token0Index: I_USDC,
        token1Index: I_USDT,
        tickSpacing: 1,
        fee: 100,
        controller: ZERO,
        tickLower: tick - 50,
        tickUpper: tick + 50,
        amount0: d3Amount,
        amount1: d3Amount,
        amount0Min: 0,
        amount1Min: 0,
        to: dsaWallet0.address
      };
      const receipt = await cast([operateSpell(3, 0, 0, encodeCreateDex(3, params), [USDC, USDT], [d3Amount, d3Amount])]);
      nftId = mintedNftId(receipt);

      expect(usdcBefore.sub(await usdc.balanceOf(dsaWallet0.address))).to.be.gt(0).and.lte(d3Amount);
      expect(usdtBefore.sub(await usdt.balanceOf(dsaWallet0.address))).to.be.gt(0).and.lte(d3Amount);
      expect((await hfInfo(nftId)).collateralValue).to.be.gt(0);
    });

    it("should borrow a D4 USDC/USDT position into the DSA (operate)", async function () {
      const tick = await currentTick(4, stableKey);
      const usdcBefore = await usdc.balanceOf(dsaWallet0.address);
      const usdtBefore = await usdt.balanceOf(dsaWallet0.address);

      const params = {
        token0Index: I_USDC,
        token1Index: I_USDT,
        tickSpacing: 1,
        fee: 100,
        controller: ZERO,
        tickLower: tick - 50,
        tickUpper: tick + 50,
        amount0: d4Amount,
        amount1: d4Amount,
        amount0Min: 0,
        amount1Min: 0,
        to: dsaWallet0.address
      };
      await cast([operateSpell(4, nftId, 0, encodeCreateDex(4, params), [USDC, USDT], [0, 0])]);

      expect((await usdc.balanceOf(dsaWallet0.address)).sub(usdcBefore)).to.be.gt(0).and.lte(d4Amount);
      expect((await usdt.balanceOf(dsaWallet0.address)).sub(usdtBefore)).to.be.gt(0).and.lte(d4Amount);
      expect((await hfInfo(nftId)).debtValue).to.be.gt(0);
    });

    it("should pay back half of the D4 debt (operate)", async function () {
      const half = d4Amount.div(2);
      const debtBefore = (await hfInfo(nftId)).debtValue;

      await cast([operateSpell(4, nftId, 2, encodeDex(half.mul(-1), half.mul(-1), dsaWallet0.address), [USDC, USDT], [half, half])]);

      expect((await hfInfo(nftId)).debtValue).to.be.lt(debtBefore);
    });

    // The DexV2 pools run with no float and maxCap 0 since go-live: a full D4 payback folds the dust through
    // Liquidity and panics (0x11). Known, not a connector issue; it clears once Team MS1 funds the float + maxCap.
    it("full D4 payback currently reverts on the live pools (no float / maxCap 0)", async function () {
      const all = parseUnits("1000000", 6);
      await expect(cast([operateSpell(4, nftId, 2, encodeDex(all.mul(-1), all.mul(-1), dsaWallet0.address), [USDC, USDT], [d4Amount, d4Amount])])).to.be.reverted;
    });

    it("should forward the D3 minimums (operateWithIds)", async function () {
      const part = parseUnits("100", 6);
      const unattainable = abiCoder.encode(["int256", "int256", "uint256", "uint256", "address"], [part.mul(-1), part.mul(-1), part.mul(10), 0, ZERO]);
      await expect(cast([operateWithIdsSpell(3, nftId, 1, unattainable, [USDC, USDT], [0, 0], noIds, noIds)])).to.be.reverted;

      const colBefore = (await hfInfo(nftId)).collateralValue;
      await cast([operateWithIdsSpell(3, nftId, 1, encodeDex(part.mul(-1), part.mul(-1), ZERO), [USDC, USDT], [0, 0], noIds, noIds)]);
      expect((await hfInfo(nftId)).collateralValue).to.be.lt(colBefore);
    });

    it("should withdraw part of the D3 position (operate)", async function () {
      const part = parseUnits("200", 6);
      const usdcBefore = await usdc.balanceOf(dsaWallet0.address);
      const colBefore = (await hfInfo(nftId)).collateralValue;

      await cast([operateSpell(3, nftId, 1, encodeDex(part.mul(-1), part.mul(-1), dsaWallet0.address), [USDC, USDT], [0, 0])]);

      expect((await usdc.balanceOf(dsaWallet0.address)).sub(usdcBefore)).to.be.gt(0);
      expect((await hfInfo(nftId)).collateralValue).to.be.lt(colBefore);
    });
  });
});
