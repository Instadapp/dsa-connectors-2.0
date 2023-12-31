import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2Spark__factory } from "../../../typechain";
import { parseEther } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { tokens } from "../../../scripts/tests/mainnet/tokens";
import { constants } from "../../../scripts/constant/constant";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";

describe("Sparklend", function () {
  const connectorName = "SPARK-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1:Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;
  const account = "0x72a53cdbbcc1b9efa39c834a540550e23463aacb";
  let signer: any;

  const ABI = [
    "function balanceOf(address account) public view returns (uint256)",
    "function approve(address spender, uint256 amount) external returns(bool)",
    "function transfer(address recipient, uint256 amount) external returns (bool)"
  ];

  const wethContract = new ethers.Contract(tokens.weth.address, ABI);
  const daiContract = new ethers.Contract(tokens.dai.address, ABI);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            // blockNumber: 12796965,
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
      contractArtifact: ConnectV2Spark__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account]
    });
    signer = await ethers.getSigner(account);
  });

  it("should have contracts deployed", async () => {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
    });
  });

  describe("Main", function () {
    it("should deposit ETH in Sparklend", async function () {
      const amt = parseEther("1");
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, amt, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
        parseEther("9")
      );
    });

    it("Should borrow and payback DAI from Sparklend", async function () {
      const amt = parseEther("100"); // 100 DAI
      const setId = "83478237";
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.dai.address, amt, 2, 0, setId],
        },
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.dai.address, amt, 2, setId, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });

    it("Should borrow and payback half DAI from Sparklend", async function () {
      const amt = parseEther("100"); // 100 DAI
      // const setId = "83478237";
      await addLiquidity("dai", dsaWallet0.address, parseEther("1"));
      let spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.dai.address, amt, 2, 0, 0],
        },
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.dai.address, amt.div(2), 2, 0, 0],
        },
      ];

      let tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );

      spells = [
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.dai.address, constants.max_value, 2, 0, 0],
        },
      ];

      tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("9")
      );
    });

    it("Should deposit all ETH in Sparklend", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, constants.max_value, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("0")
      );
    });

    it("Should withdraw all ETH from Sparklend", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, constants.max_value, 0, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });

    it("should deposit and withdraw", async () => {
      const amt = parseEther("1"); // 1 eth
      const setId = "834782373";
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, amt, 0, setId],
        },
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, amt, setId, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });

    it("should deposit without collateral and withdraw", async () => {
      const amt = parseEther("1"); // 1 eth
      const setId = "834782373";
      const spells = [
        {
          connector: connectorName,
          method: "depositWithoutCollateral",
          args: [tokens.eth.address, amt, 0, setId],
        },
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, amt, setId, 0],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });

    // it("should deposit ETH in Sparklend", async function () {
    //   const amt = parseEther("1");
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "deposit",
    //       args: [tokens.eth.address, amt, 0, 0],
    //     },
    //     {
    //       connector: connectorName,
    //       method: "borrow",
    //       args: [tokens.dai.address, amt.mul(300), 2, 0, 0],
    //     },
    //     {
    //       connector: connectorName,
    //       method: "paybackWithATokens",
    //       args: [tokens.dai.address, amt.mul(300), 2, 0, 0],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
    //     parseEther("9")
    //   );
    // });

  });
});
