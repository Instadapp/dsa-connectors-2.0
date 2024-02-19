import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2Fluid, ConnectV2Fluid__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { constants } from "../../../scripts/constant/constant";
import { network, ethers } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

describe("Fluid", function () {
  const connectorName = "FLUID";
  let connector: any;

  let wallet0: Signer, wallet1: Signer, wstethHolderSigner: Signer;
  let nftId = "6";
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;

  const vaultWstethEth = "0x28680f14C4Bb86B71119BC6e90E4e6D87E6D1f51";

  const wstethHolder = "0x17170904077C84F26c190eC05fF414B7045F4652";

  const WSTETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0";

  const erc20Abi = [
    {
      constant: false,
      inputs: [
        {
          name: "_spender",
          type: "address"
        },
        {
          name: "_value",
          type: "uint256"
        }
      ],
      name: "approve",
      outputs: [
        {
          name: "",
          type: "bool"
        }
      ],
      payable: false,
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      constant: true,
      inputs: [],
      name: "totalSupply",
      outputs: [
        {
          name: "",
          type: "uint256"
        }
      ],
      payable: false,
      stateMutability: "view",
      type: "function"
    },
    {
      constant: true,
      inputs: [
        {
          name: "_owner",
          type: "address"
        }
      ],
      name: "balanceOf",
      outputs: [
        {
          name: "balance",
          type: "uint256"
        }
      ],
      payable: false,
      stateMutability: "view",
      type: "function"
    },
    {
      constant: false,
      inputs: [
        {
          name: "_to",
          type: "address"
        },
        {
          name: "_value",
          type: "uint256"
        }
      ],
      name: "transfer",
      outputs: [
        {
          name: "",
          type: "bool"
        }
      ],
      payable: false,
      stateMutability: "nonpayable",
      type: "function"
    }
  ];

  const wstethToken = new ethers.Contract(WSTETH, erc20Abi);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 19261868,
          },
        },
      ],
    });

    [wallet0, wallet1] = await ethers.getSigners();
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2,
      masterSigner
    );
    
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Fluid__factory,
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
    });

    it("Deposit 20 Wsteth into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: wstethHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wstethHolder]
      });
  
      wstethHolderSigner = await ethers.getSigner(wstethHolder);
  
      await wstethToken.connect(wstethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("20"));

      expect(await wstethToken.connect(wstethHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("20"));
    });
  });

  // 200 wsteth

  describe("Main", function () {
    it("should deposit 10 wsteth in Fluid", async function () {
      const amtDeposit = parseEther("10");

      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth,
            '0', // new nft
            amtDeposit, // +10 collateral
            '0', // 0 debt
            '0'
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      const receipt = await tx.wait();

      const eventName = "LogOperate(address,uint256,int256,int256)";
      const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

      const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
      //   parseEther("1000")
      // );
    });
    // 90 wsteth

    it("should deposit max wsteth in Fluid", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth, // matic-usdc vault
            nftId, // new nft
            ethers.constants.MaxInt256, // + max collateral
            0, // 0 debt
            0
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.lte(
      //   parseEther("1")
      // );
    });

    // 0 wsteth

    it("Should borrow 1 ETH", async function () {
      const amtBorrow = parseEther("1"); // 1 eth
      
      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth,
            nftId,
            0,
            amtBorrow,
            0
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
      //   parseEther("0.099")
      // );
    });

    // 0 wsteth, 1 eth

    it("Should payback max eth", async function () {
      await network.provider.send("hardhat_setBalance", [
        dsaWallet0.address,
        ethers.utils.parseEther("2.0").toHexString(),
      ]);

      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth,
            nftId,
            0,
            ethers.constants.MinInt256,
            new BigNumber(parseEther("1").toString()),
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
      //   ethers.utils.parseEther("0.2")
      // );
    });

    // 0 wsteth, 1 eth

    it("Should withdraw 2 wsteth", async function () {
      const amt = new BigNumber(parseEther("2").toString()).multipliedBy(-1); // 100 Matic

      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth,
            nftId,
            amt,
            0, // 0 debt
            0
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
      //   parseEther("100")
      // );
    });

    // 2 wsteth, 1 eth

    it("Should withdraw max wsteth", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultWstethEth,
            nftId,
            ethers.constants.MinInt256, // min integer value
            0,
            0
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
      //   parseEther("2000")
      // );
    });

    //  wsteth, 1 eth
  });
});
