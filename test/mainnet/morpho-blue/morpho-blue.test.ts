import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2MorphoBlue__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { dsaMaxValue, tokens } from "../../../scripts/tests/mainnet/tokens";

const { ethers } = hre;
import type { Signer, Contract } from "ethers";

const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const ACC_USDC = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0";
const Usdc = parseUnits("5000", 6);

const DAI = "0x6b175474e89094c44da98b954eedeac495271d0f";
const ACC_DAI = "0xcd6Eb888e76450eF584E8B51bB73c76ffBa21FF2";
const Dai = parseUnits("1", 18);

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

const user = "0x41bc7d0687e6cea57fa26da78379dfdc5627c56d";

const tokenBI = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationCanceled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationUsed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"Blacklisted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newBlacklister","type":"address"}],"name":"BlacklisterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"burner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newMasterMinter","type":"address"}],"name":"MasterMinterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"MinterConfigured","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"oldMinter","type":"address"}],"name":"MinterRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":false,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[],"name":"Pause","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newAddress","type":"address"}],"name":"PauserChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newRescuer","type":"address"}],"name":"RescuerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"UnBlacklisted","type":"event"},{"anonymous":false,"inputs":[],"name":"Unpause","type":"event"},{"inputs":[],"name":"CANCEL_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RECEIVE_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"TRANSFER_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"authorizationState","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"blacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"blacklister","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"cancelAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"cancelAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"},{"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"configureMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"currency","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"decrement","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"increment","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"tokenName","type":"string"},{"internalType":"string","name":"tokenSymbol","type":"string"},{"internalType":"string","name":"tokenCurrency","type":"string"},{"internalType":"uint8","name":"tokenDecimals","type":"uint8"},{"internalType":"address","name":"newMasterMinter","type":"address"},{"internalType":"address","name":"newPauser","type":"address"},{"internalType":"address","name":"newBlacklister","type":"address"},{"internalType":"address","name":"newOwner","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"newName","type":"string"}],"name":"initializeV2","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"lostAndFound","type":"address"}],"name":"initializeV2_1","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"accountsToBlacklist","type":"address[]"},{"internalType":"string","name":"newSymbol","type":"string"}],"name":"initializeV2_2","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"isBlacklisted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"masterMinter","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"minterAllowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pauser","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"receiveWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"receiveWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"removeMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"tokenContract","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"rescueERC20","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rescuer","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"bytes","name":"signature","type":"bytes"}],"name":"transferWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"transferWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"unBlacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newBlacklister","type":"address"}],"name":"updateBlacklister","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newMasterMinter","type":"address"}],"name":"updateMasterMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newPauser","type":"address"}],"name":"updatePauser","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newRescuer","type":"address"}],"name":"updateRescuer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"pure","type":"function"}]

const token_usdc = new ethers.Contract(USDC, tokenBI, ethers.provider);

const token_dai = new ethers.Contract(DAI, tokenBI, ethers.provider);

const token_weth = new ethers.Contract(WETH, tokenBI, ethers.provider);

describe("Morpho-Blue", function () {
  const connectorName = "MORPHO-BLUE-TEST-A";
  let connector: any;

  let wallet0: Signer, wallet1: Signer;
  let dsaWallet0: any;
  let dsaWallet1: any;
  let instaConnectorsV2: Contract;
  let masterSigner: Signer;

  let irm = "0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC"

  let loanToken1 = "0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC" // weth
  let collateralToken1 = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0" // wsteth
  let oracle1 = "0x2a01EB9496094dA03c4E364Def50f5aD1280AD72"
  let lltv1 = "945000000000000000"

  let loanToken2 = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48" // usdc
  let collateralToken2 = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0" // wsteth
  let oracle2 = "0x48F7E36EB6B826B2dF4B2E630B62Cd25e89E40e2"
  let lltv2 = "860000000000000000"

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 17544460
          }
        }
      ]
    });
    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2MorphoBlue__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
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
    });

    it("Deposit 1000 ETH into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(parseEther("1000"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: parseEther("1000")
      });
      expect(await ethers.provider.getBalance(dsaWallet1.address)).to.be.gte(parseEther("1000"));
    });

    it("Deposit 5000 USDC into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACC_USDC]
      });

      const signer_usdc = await ethers.getSigner(ACC_USDC);
      await token_usdc.connect(signer_usdc).transfer(wallet0.getAddress(), Usdc);

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDC]
      });

      await token_usdc.connect(wallet0).transfer(dsaWallet0.address, Usdc);

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("5000", 6));
    });
  });

  describe("Main", function () {
    it("Should deposit 10 ETH", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [tokens.eth.address, "10000000000000000000", "0", "0"], // 10 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('990', 18))
      );
    })

    it("Should deposit 1 ETH with MaxIteration", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositWithMaxIterations",
          args: [tokens.eth.address, "1000000000000000000", 5, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('989', 18))
      );
    })

    it("Should deposit 10 ETH on behalf", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "10000000000000000000", user, 4, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('979', 18))
      );
    })

    it("Should deposit 1 ETH on behalf with MaxIteration", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "1000000000000000000", user, 5, "0", "0"], // 1 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        parseUnits('978', 18))
      );
    })

    it("Should deposit collateral 2000 USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "2000000000", "0", "0"], // 50 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('3000', 6)
      );
    })

    it("Should deposit collateral 2000 USDC on behalf with maxValue", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "depositCollateralOnBehalf",
          args: [tokens.usdc.address, dsaMaxValue, user, "0", "0"], // ~3000 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(await token_usdc.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(
        parseUnits('1', 6)
      );
    })

    it("Should withdraw 10 ETH", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "withdraw",
          args: [tokens.eth.address, "10000000000000000000", "0", "0"], // 10 ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect(expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseUnits('978', 18))
      );
    })

    it("Should withdraw on behalf of user with maxValue", async function () {
      let ethBala = await ethers.provider.getBalance(user)
      let wethBala = await token_weth.balanceOf(user)

      const spells = [
        {
          connector: connectorName,
          method: "withdrawOnBehalfWithMaxIterations",
          args: [tokens.eth.address, dsaMaxValue, dsaWallet0.address, user, 4, "0", "0"], // Max ETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      ethBala = await ethers.provider.getBalance(user)
      wethBala = await token_weth.balanceOf(user)

    })

    it("Should borrow ETH into DSA", async function () {
        const balanceBefore = await ethers.provider.getBalance(dsaWallet0.address);
        const spells = [
          {
            connector: connectorName,
            method: "borrow",
            args: [tokens.eth.address, "500000000000000000", "0", "0"], // 0.5 WETH
          },
        ];

        const tx = await dsaWallet0
            .connect(wallet0)
            .cast(...encodeSpells(spells), wallet1.getAddress());

        await tx.wait();
        const balanceAfter = await ethers.provider.getBalance(dsaWallet0.address);
        expect((balanceAfter).sub(balanceBefore)).to.be.gte(parseUnits('4.9', 17));
    })

    it("Should borrow ETH into user", async function () {
      const balance = await token_weth.balanceOf(user);
      const spells = [
        {
          connector: connectorName,
          method: "borrowOnBehalfWithMaxIterations",
          args: [tokens.eth.address, "200000000000000000", dsaWallet0.address, user, 4, "0", "0"], // 0.7 WETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect((await token_weth.balanceOf(user)).sub(balance))
        .to.be.eq(parseUnits('2', 17));
    })

    it("Should borrow WETH into wallet1 using iteration", async function () {
      const balance = await token_weth.balanceOf(dsaWallet0.address);
      const spells = [
        {
          connector: connectorName,
          method: "borrowWithMaxIterations",
          args: [tokens.weth.address, "20000000000000000", 10, "0", "0"], // 0.02 WETH
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
      expect((await token_weth.balanceOf(dsaWallet0.address)).sub(balance))
        .to.be.eq(parseUnits('2', 16));
    })

    it("Test withdrawCollateral ", async function () {
      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits('500', 6))

      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_USDC],
      })

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('500', 6)
      );

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "20000000", "0", "0"], // 20 USDC
        },
        {
          connector: connectorName,
          method: "withdrawCollateral",
          args: [tokens.usdc.address, "19000000", "0", "0"], // 19 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

    })

    it("Test withdrawCollateralOnBehalf with maxValue", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ACC_USDC]
      });

      const signer_usdc = await ethers.getSigner(ACC_USDC);
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits("500", 6));

      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [ACC_USDC]
      });

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("500", 6));

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      let spells = [
        {
          connector: connectorName,
          method: "approveManager",
          args: [dsaWallet0.address, true] // 20 USDC
        },
      ];

      let tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();

      spells = [
        {
          connector: connectorName,
          method: "depositCollateralOnBehalf",
          args: [tokens.usdc.address, "20000000", dsaWallet1.address, "0", "0"] // 20 USDC
        },
        {
          connector: connectorName,
          method: "withdrawCollateralOnBehalf",
          args: [tokens.usdc.address, dsaMaxValue, dsaWallet1.address, user, "0", "0"] // 20 USDC
        }
      ];

      tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("499", 6));
      
    });

    it("Test payback with maxValue", async function () {
      await hre.network.provider.request({
        method: 'hardhat_impersonateAccount',
        params: [ACC_USDC],
      })

      const signer_usdc = await ethers.getSigner(ACC_USDC)
      await token_usdc.connect(signer_usdc).transfer(dsaWallet0.address, parseUnits('500', 6))

      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_USDC],
      })

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('500', 6)
      );

      const balance = await token_usdc.balanceOf(dsaWallet0.address);

      const spells = [
        {
          connector: connectorName,
          method: "depositCollateral",
          args: [tokens.usdc.address, "200000000", "0", "0"], // 2 ETH
        },
        {
          connector: connectorName,
          method: "borrow",
          args: [tokens.eth.address, "1000000000000000", "0", "0"], // 20 USDC
        },
        {
          connector: connectorName,
          method: "payback",
          args: [tokens.eth.address, dsaMaxValue, "0", "0"], // 20 USDC
        },
      ];

      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await token_usdc.connect(masterSigner).balanceOf(dsaWallet0.address)).to.be.gte(
        parseUnits('499', 6)
      );
    })

    it("approve manger", async () => {
      const spells = [
        {
          connector: connectorName,
          method: "approveManager",
          args: [user, true],
        },
      ]
      const tx = await dsaWallet0
          .connect(wallet0)
          .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();
    })
  });
});
