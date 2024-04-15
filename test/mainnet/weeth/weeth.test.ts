import hre from "hardhat";
import { expect } from "chai";
const { ethers } = hre;
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2WEETH__factory } from "../../../typechain";
import type { Signer, Contract } from "ethers";

describe("Wrapping / Unwrapping eETH", function () {
  const connectorName = "weETH-test";

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
      contractArtifact: ConnectV2WEETH__factory,
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

    it("Topup eETH into DSA wallet", async function () {
      const eETHTAddress = "0x35fA164735182de50811E8e2E824cFb9B6118ac2";
      const IERC20ABI = [
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function balanceOf(address account) external view returns (uint256)",
        "function transfer(address recipient, uint256 amount) external returns (bool)",
      ];
      const eETHHolder = "0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee";
      const amount = ethers.utils.parseEther("10");

      const eETHContract = await ethers.getContractAt(IERC20ABI, eETHTAddress);
      await hre.network.provider.send("hardhat_setBalance", [
        eETHHolder,
        "0x56BC75E2D63100000",
      ]);

      console.log(
        "Holder eETH Balance before topup:",
        ethers.utils.formatEther(await eETHContract.balanceOf(eETHHolder))
      );
      console.log(
        "holder ETH Balance before topup:",
        ethers.utils.formatEther(await ethers.provider.getBalance(eETHHolder))
      );
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [eETHHolder],
      });
      const eETHHolderSigner = await ethers.getSigner(eETHHolder);
      await eETHContract
        .connect(eETHHolderSigner)
        .approve(dsaWallet0.address, amount);
      await eETHContract
        .connect(eETHHolderSigner)
        .transfer(dsaWallet0.address, amount);
      const balance = await eETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "DSA eETH Balance after topup:",
        ethers.utils.formatEther(balance)
      );

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [eETHHolder],
      });
    });
  });
  describe("Main", function () {
    it("Should wrap and unwrap eETH", async function () {
      const eETHTAddress = "0x35fA164735182de50811E8e2E824cFb9B6118ac2";
      const weETHAddress = "0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee";
      const IERC20ABI = [
        "function balanceOf(address account) external view returns (uint256)",
      ];
      const eETHContract = await ethers.getContractAt(IERC20ABI, eETHTAddress);
      const weETHContract = await ethers.getContractAt(IERC20ABI, weETHAddress);
      const amount = ethers.utils.parseEther("10");
      const initialBalance = await weETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "weETH Balance before wrapping:",
        ethers.utils.formatEther(initialBalance)
      );
      console.log("Wrapping 10 eETH to weETH");
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
        .cast(...spellsEncoded, await wallet1.getAddress());
      const receipt = await tx.wait();
      const finalBalance = await weETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "weETH Balance after wrapping:",
        ethers.utils.formatEther(finalBalance)
      );

      const uint256Max = ethers.BigNumber.from(2).pow(256).sub(1);
      const initialBalance2 = await eETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "eETH Balance before unwrapping:",
        ethers.utils.formatEther(initialBalance2)
      );
      console.log("Unwrapping all eETH to ETH");
      const spells2 = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [uint256Max, 0, 0],
        },
      ];
      const spellsEncoded2 = encodeSpells(spells2);
      const tx2 = await dsaWallet0
        .connect(wallet0)
        .cast(...spellsEncoded2, await wallet1.getAddress());
      const receipt2 = await tx2.wait();
      const finalBalance2 = await eETHContract.balanceOf(dsaWallet0.address);
      console.log(
        "eETH Balance after unwrapping:",
        ethers.utils.formatEther(finalBalance2)
      );
    });
  });
});
