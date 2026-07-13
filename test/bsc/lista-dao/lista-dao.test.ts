import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/bsc/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2ListaDaoBSC__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { dsaMaxValue } from "../../../scripts/tests/mainnet/tokens";

const { ethers } = hre;
import type { Signer, Contract } from "ethers";

const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const BTCB = "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c";
const BNB = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

const ERC20_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function approve(address spender, uint256 amount) returns (bool)",
];

describe("Lista-DAO", function () {
  const connectorName = "LISTA-DAO-TEST-A";
  let connector: Contract;

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: any;
  let dsaWallet1: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;

  // Lista DAO (Moolah) on BSC - market params for BNB/WBNB collateralized borrow
  // Update oracle, irm, lltv from Lista docs if needed for your fork block
  const irm = "0xFe7dAe87Ebb11a7BEB9F534BB23267992d9cDe7c";
  const loanToken = BTCB;
  const collateralToken = WBNB;
  const oracle = "0xf3afD82A4071f272F403dC176916141f44E6c750";
  const lltv = "800000000000000000"; // 80%
  const marketParams = [loanToken, collateralToken, oracle, irm, lltv];

  // 2nd Vault:
  const irm2 = "0xFe7dAe87Ebb11a7BEB9F534BB23267992d9cDe7c";
  const loanToken2 = WBNB;
  const collateralToken2 = BTCB;
  const oracle2 = "0xf3afD82A4071f272F403dC176916141f44E6c750";
  const lltv2 = "800000000000000000"; // 80%
  const marketParams2 = [loanToken2, collateralToken2, oracle2, irm2, lltv2];

  console.log("marketParams", marketParams);

  const tokenWbnb = new ethers.Contract(WBNB, ERC20_ABI, ethers.provider);
  const tokenBtcb = new ethers.Contract(BTCB, ERC20_ABI, ethers.provider);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: `https://bnb-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
            blockNumber: 85986633,
          },
        },
      ],
    });
    [wallet0, wallet1] = await ethers.getSigners();
    console.log("wallet0", wallet0.address);
    console.log("wallet1", wallet1.address);

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2ListaDaoBSC__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
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
      dsaWallet1 = await buildDSAv2(wallet0.getAddress());
      expect(!!dsaWallet1.address).to.be.true;

      console.log("dsaWallet0", dsaWallet0.address);
      console.log("dsaWallet1", dsaWallet1.address);
    });

    it("Deposit BNB into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("10")
      );
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(
        parseEther("10")
      );
    });

    it("Deposit WBNB into DSA wallet", async function () {
      const holderAddress = "0x308000D0169Ebe674B7640f0c415f44c6987d04D"
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [holderAddress]
      });
      const holderSigner = await ethers.getSigner(holderAddress);
      await tokenWbnb.connect(holderSigner).transfer(dsaWallet0.address, parseUnits("100", 18));
      expect(await tokenWbnb.balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("100", 18));
    });

    it("Deposit BTCB into DSA wallet", async function () {
     const holderAddress = "0x5a52E96BAcdaBb82fd05763E25335261B270Efcb"
     await hre.network.provider.request({
       method: "hardhat_impersonateAccount",
       params: [holderAddress]
     });
     const holderSigner = await ethers.getSigner(holderAddress);
     await tokenBtcb.connect(holderSigner).transfer(dsaWallet0.address, parseUnits("1", 18));
     expect(await tokenBtcb.balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("1", 18));
    });
  });

  describe("Main - marketParams (BTCB/WBNB)", function () {
    it("Should supply collateral", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "supply",
          args: [
            marketParams,
            dsaWallet0.address,
            parseUnits("0.05", 18).toString(),
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should borrow", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [
            marketParams,
            dsaWallet0.address,
            parseUnits("0.00022", 18).toString(),
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should repay", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [
            marketParams,
            dsaWallet0.address,
            "5000000000000",
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should withdraw", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [
            marketParams,
            dsaWallet0.address,
            "1000000000000000",
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });
  });

  describe("Main - marketParams2 (WBNB/BTCB)", function () {
    it("Should supply collateral (marketParams2)", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "supply",
          args: [
            marketParams2,
            dsaWallet0.address,
            parseUnits("0.05", 18).toString(),
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should borrow (marketParams2)", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "borrow",
          args: [
            marketParams2,
            dsaWallet0.address,
            parseUnits("2", 18).toString(),
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should repay (marketParams2)", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [
            marketParams2,
            dsaWallet0.address,
            parseUnits("1", 18).toString(),
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });

    it("Should withdraw (marketParams2)", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [
            marketParams2,
            dsaWallet0.address,
            "1000000000000000",
            "0",
            "0",
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet0.getAddress());

      await tx.wait();
    });
  });
});
