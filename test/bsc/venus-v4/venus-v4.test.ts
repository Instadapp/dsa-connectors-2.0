import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/bsc/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2VenusCoreBSC__factory } from "../../../typechain";
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import type { Signer, Contract } from "ethers";

const { ethers } = hre;

const BNB = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
const USDT = "0x55d398326f99059fF775485246999027B3197955";
const vBNB = "0xA07c5b74C9B40447a954e1466938b865b6BBea36";
const vUSDT = "0xfD5840Cd36d94D7229439859C0112a4185BC0255";

const VTOKEN_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function borrowBalanceCurrent(address account) returns (uint256)",
];
const ERC20_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
];

describe("Venus Core BSC", function () {
  const connectorName = "VENUS-CORE-BSC-TEST-A";

  let connector: Contract;
  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;
  let borrowedBnbAmt = parseEther("0.005");

  const vBnbContract = new ethers.Contract(vBNB, VTOKEN_ABI, ethers.provider);
  const vUsdtContract = new ethers.Contract(vUSDT, VTOKEN_ABI, ethers.provider);
  const usdtContract = new ethers.Contract(USDT, ERC20_ABI, ethers.provider);

  before(async () => {
    console.log("ALCHEMY_API_KEY", process.env.ALCHEMY_API_KEY);
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          hardfork: "cancun",
          forking: {
            // @ts-ignore
            jsonRpcUrl: `https://bnb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
            blockNumber: 92671196,
          },
        },
      ],
    });
    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();

    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2VenusCoreBSC__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit BNB into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
    });

    it("Deposit USDT into DSA wallet", async function () {
      const holderAddress = "0x8894E0a0c962CB723c1976a4421c95949bE2D4E3";
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [holderAddress],
      });
      const holderSigner = await ethers.getSigner(holderAddress);
      await (await usdtContract.connect(holderSigner).transfer(dsaWallet0.address, "10000000000000000000")).wait(); // 200 USDT
      expect(await usdtContract.balanceOf(dsaWallet0.address)).to.be.gte("10000000000000000000");
    });
  });

  describe("Main", function () {
    // it("Should deposit USDT into Venus", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "deposit",
    //       args: [USDT, vUSDT, "1000000000000000000", 0, 0], // 1 USDT
     
    //     },
    //   ];

    //   await (
    //     await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress())
    //   ).wait();

    //   expect(await vUsdtContract.balanceOf(dsaWallet0.address)).to.be.gt(0);
    // });

    it("Should deposit BNB into Venus", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [BNB, vBNB, "1000000000000000000", 0, 0], // 1 BNB
     
        },
      ];

      await (
        await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress())
      ).wait();

      expect(await vBnbContract.balanceOf(dsaWallet0.address)).to.be.gt(0);
    });

    // it("Should disable and enable collateral", async function () {
    //   const disableSpells = [
    //     { connector: connectorName, method: "disableCollateral", args: [[vUSDT]] },
    //   ];
    //   await (
    //     await dsaWallet0
    //       .connect(wallet0)
    //       .cast(...encodeSpells(disableSpells), await wallet1.getAddress())
    //   ).wait();

    //   const enableSpells = [
    //     { connector: connectorName, method: "enableCollateral", args: [[vUSDT]] },
    //   ];
    //   await (
    //     await dsaWallet0
    //       .connect(wallet0)
    //       .cast(...encodeSpells(enableSpells), await wallet1.getAddress())
    //   ).wait();
    // });

    // it("Should borrow BNB", async function () {
    //   const borrowAmt = parseEther("0.005");
    //   borrowedBnbAmt = borrowAmt;
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "borrow",
    //       args: [BNB, vBNB, borrowAmt, 0, 0],
    //     },
    //   ];

    //   await (
    //     await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress())
    //   ).wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gt(parseEther("2"));
    //   expect(await vBnbContract.borrowBalanceCurrent(dsaWallet0.address)).to.be.gt(0);
    // });

    // it("Should repay borrowed BNB debt", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "repay",
    //       args: [BNB, vBNB, borrowedBnbAmt, 0, 0],
    //     },
    //   ];

    //   await (
    //     await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress())
    //   ).wait();

    //   expect(await vBnbContract.borrowBalanceCurrent(dsaWallet0.address)).to.eq(0);
    // });

    // it("Should withdraw BNB", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "withdraw",
    //       args: [USDT, vUSDT, "100000000", 0, 0],
    //     },
    //   ];

    //   await (
    //     await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), await wallet1.getAddress())
    //   ).wait();

    //   expect(await vUsdtContract.balanceOf(dsaWallet0.address)).to.eq(0);
    //   expect(await usdtContract.balanceOf(dsaWallet0.address)).to.be.gte("190000000");
    // });
  });
});

