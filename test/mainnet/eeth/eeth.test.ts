import hre from "hardhat";
import { expect } from "chai";
const { ethers } = hre;
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2EETH__factory } from "../../../typechain";
import type { Signer, Contract } from "ethers";

describe("eETH Staking", function () {
  const connectorName = "eETH-test";

  let dsaWallet0: Contract;
  let wallet0: Signer, wallet1: Signer;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;

  before(async () => {
    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2EETH__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(await wallet0.getAddress());
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );
    });
    it("Topup wETH into DSA wallet", async function () {
        const wETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
        const IERC20ABI = [
          "function approve(address spender, uint256 amount) external returns (bool)",
          "function balanceOf(address account) external view returns (uint256)",
          "function transfer(address recipient, uint256 amount) external returns (bool)",
        ];
        const wETHHolder = "0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E";
        const amount = ethers.utils.parseEther("10");
  
        const eETHContract = await ethers.getContractAt(IERC20ABI, wETHAddress);
        await hre.network.provider.send("hardhat_setBalance", [
            wETHHolder,
          "0x56BC75E2D63100000",
        ]);
  
        console.log(
          "Holder wETH Balance before topup:",
          ethers.utils.formatEther(await eETHContract.balanceOf(wETHHolder))
        );
        console.log(
          "Holder ETH Balance before topup:",
          ethers.utils.formatEther(await ethers.provider.getBalance(wETHHolder))
        );
        await hre.network.provider.request({
          method: "hardhat_impersonateAccount",
          params: [wETHHolder],
        });
        const eETHHolderSigner = await ethers.getSigner(wETHHolder);
        await eETHContract
          .connect(eETHHolderSigner)
          .approve(dsaWallet0.address, amount);
        await eETHContract
          .connect(eETHHolderSigner)
          .transfer(dsaWallet0.address, amount);
        const balance = await eETHContract.balanceOf(dsaWallet0.address);
        console.log(
          "DSA wETH Balance after topup:",
          ethers.utils.formatEther(balance)
        );
  
        await hre.network.provider.request({
          method: "hardhat_stopImpersonatingAccount",
          params: [wETHHolder],
        });
      });
  });

  describe("Main", function () {
    it("Should deposit ETH into eETH", async function () {
      const amount = ethers.utils.parseEther("1");
      const eETHTAddress = "0x35fA164735182de50811E8e2E824cFb9B6118ac2";
      const IERC20ABI = [
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function balanceOf(address account) external view returns (uint256)",
      ];
      const eETHContract = await ethers.getContractAt(IERC20ABI, eETHTAddress);

      const initialBalance = await eETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "eETH Balance before:",
        ethers.utils.formatEther(initialBalance)
      );

      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [amount, 0, 0],
        },
      ];

      const spellsEncoded = encodeSpells(spells);
      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet1.getAddress());
      const receipt = await tx.wait();

      const finalBalance = await eETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "eETH Balance after:",
        ethers.utils.formatEther(finalBalance)
      );
    });

    it("Should deposit wETH into eETH", async function () {
        const amount = ethers.utils.parseEther("1");
        const eETHTAddress = "0x35fA164735182de50811E8e2E824cFb9B6118ac2";
        const IERC20ABI = [
          "function approve(address spender, uint256 amount) external returns (bool)",
          "function balanceOf(address account) external view returns (uint256)",
        ];
        const eETHContract = await ethers.getContractAt(IERC20ABI, eETHTAddress);
  
        const initialBalance = await eETHContract.balanceOf(dsaWallet0.address);
        console.log(
          "eETH Balance before:",
          ethers.utils.formatEther(initialBalance)
        );

        const spells = [
          {
            connector: connectorName,
            method: "depositWeth",
            args: [amount, 0, 0],
          },
        ];

        const spellsEncoded = encodeSpells(spells);
        const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), await wallet1.getAddress());
        const receipt = await tx.wait();

        const finalBalance = await eETHContract.balanceOf(dsaWallet0.address);
        console.log(
          "eETH Balance after:",
          ethers.utils.formatEther(finalBalance)
        );
    });
  });
});
