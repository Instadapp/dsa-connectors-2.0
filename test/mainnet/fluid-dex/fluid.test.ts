import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2FluidVaultT4, ConnectV2FluidVaultT4__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { constants } from "../../../scripts/constant/constant";
import { network, ethers } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

describe("Fluid Dex", function () {
  const connectorName = "FLUID-DEX";
  let connector: any;

  let wallet0: Signer, wallet1: Signer, wstethHolderSigner: Signer;
  let nftId = "6";
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;

  // const vaultWstethEth = "0x28680f14C4Bb86B71119BC6e90E4e6D87E6D1f51";
  const vaultT4Address = "0x57fed7c9b3c763999c519264931790cBcA331417";

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
            blockNumber: 20995500,
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
      contractArtifact: ConnectV2FluidVaultT4__factory,
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

    it("Deposit 20 Eth into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("20"),
      });
      // expect(await wstethToken.connect(wstethHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("20"));
    });
  });

  // 20 wsteth 20 eth

  describe("Main", function () {
    // it("should deposit 10 in Fluid Dex", async function () {
    //   const amtDepositWsteth = parseEther("10");
    //   const amtDepositEth = parseEther("10");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operateWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultWstethEth,
    //         nftId: '0',
    //         newColToken0: amtDepositWsteth,
    //         newColToken1: amtDepositEth,
    //         colSharesMinMax: '0',
    //         newDebtToken0: '0',
    //         newDebtToken1: '0',
    //         debtSharesMinMax: '0',
    //         getIds: ['0','0','0','0','0','0','0','0','0'],
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }]
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();

    //   const eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // // 11 wsteth 11 eth
    // it("Should borrow 1 ETH", async function () {
    //   const amtBorrowWsteth = parseEther("1"); // 1 eth
    //   const amtBorrowEth = parseEther("1"); // 1 eth
      
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operateWithIds",
    //       args: [{
    //         vaultAddress: vaultWstethEth,
    //         nftId: nftId,
    //         newColToken0: '0',
    //         newColToken1: '0',
    //         colSharesMinMax: '0',
    //         newDebtToken0: amtBorrowWsteth,
    //         newDebtToken1: amtBorrowEth,
    //         debtSharesMinMax: '0',
    //         getIds: ['0','0','0','0','0','0','0','0','0'],
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }]
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
    //   //   parseEther("0.099")
    //   // );
    // });

    // // 6 wsteth 6 eth
    // it("should deposit and borrow wsteth using operate perfect", async function () {
    //   const amtDepositWsteth = parseEther("5");
    //   const amtDepositEth = parseEther("5");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultWstethEth,
    //         nftId: '0', // new nft
    //         perfectColShares: amtDepositWsteth, // +10 collateral // newColToken0_
    //         colToken0MinMax: amtDepositEth, // +10 collateral // newColToken1_
    //         colToken1MinMax: '0', // colSharesMinMax_
    //         perfectDebtShares: '0', // newDebtToken0_
    //         debtToken0MinMax: '0', // newDebtToken1_
    //         debtToken1MinMax: '0', // debtSharesMinMax_
    //         getNftId: Array(9).fill('0'),
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();

    //   const eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // it("should payback and withdraw using operate perfect", async function () {
    //   const amtDepositWsteth = parseEther("5");
    //   const amtDepositEth = parseEther("5");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultWstethEth,
    //         nftId: '0', // new nft
    //         perfectColShares: amtDepositWsteth, // +10 collateral // newColToken0_
    //         colToken0MinMax: amtDepositEth, // +10 collateral // newColToken1_
    //         colToken1MinMax: '0', // colSharesMinMax_
    //         perfectDebtShares: '0', // newDebtToken0_
    //         debtToken0MinMax: '0', // newDebtToken1_
    //         debtToken1MinMax: '0', // debtSharesMinMax_
    //         getNftId: Array(9).fill('0'),
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();

    //   const eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // // 6 wsteth 6 eth
    // it("should deposit max and borrow using operate perfect", async function () {
    //   const amtDepositWsteth = parseEther("5");
    //   const amtDepositEth = parseEther("5");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultWstethEth,
    //         nftId: '0', // new nft
    //         perfectColShares: amtDepositWsteth, // +10 collateral // newColToken0_
    //         colToken0MinMax: amtDepositEth, // +10 collateral // newColToken1_
    //         colToken1MinMax: '0', // colSharesMinMax_
    //         perfectDebtShares: '0', // newDebtToken0_
    //         debtToken0MinMax: '0', // newDebtToken1_
    //         debtToken1MinMax: '0', // debtSharesMinMax_
    //         getNftId: Array(9).fill('0'),
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();

    //   const eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // // 6 wsteth 6 eth
    // it("should payback max and withdraw max using operate perfect", async function () {
    //   const amtDepositWsteth = parseEther("5");
    //   const amtDepositEth = parseEther("5");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultWstethEth,
    //         nftId: '0', // new nft
    //         perfectColShares: amtDepositWsteth, // +10 collateral // newColToken0_
    //         colToken0MinMax: amtDepositEth, // +10 collateral // newColToken1_
    //         colToken1MinMax: '0', // colSharesMinMax_
    //         perfectDebtShares: '0', // newDebtToken0_
    //         debtToken0MinMax: '0', // newDebtToken1_
    //         debtToken1MinMax: '0', // debtSharesMinMax_
    //         getNftId: Array(9).fill('0'),
    //         setIds: ['0','0','0','0','0','0','0','0','0']
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();

    //   const eventName = "LogOperateWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256[],uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    it("should deposit and borrow using operate perfect", async function () {
        const perfectColShares = parseEther("0.5"); // 5e17
        const perfectDebtShares = parseEther("0.2"); // 2e17
  
        const spells = [
          {
            connector: connectorName,
            method: "operatePerfectWithIds",
            args: [
            {
              vaultAddress: vaultT4Address,
              nftId: '0', // TODO: update
              perfectColShares: perfectColShares, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
              colToken0MinMax: parseEther("2"), // 1e21
              colToken1MinMax: parseEther("2"), // 1e21
              perfectDebtShares: perfectDebtShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
              debtToken0MinMax: '1', // very small number
              debtToken1MinMax: '1', // very small number
              getNftId: 0,
              setIds: Array(9).fill('0')
            }
          ],
          },
        ];
  
        // Execute the cast transaction with encoded spells
        const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), await wallet1.getAddress());

      // Wait for the transaction to be mined
      const receipt = await tx.wait();
      console.log('Transaction receipt received.');  
  
        // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
        //   parseEther("1000")
        // );
    });

    it("should payback and withdraw using operate perfect", async function () {
      const nftId = 2297 // Based on block 20995500

      const perfectColWithdrawShares = "-200000000000000000"; // 0.2
      const perfectDebtPaybackShares = "-100000000000000000"; // 0.1

      const spells = [
        {
          connector: connectorName,
          method: "operatePerfectWithIds",
          args: [
          {
            vaultAddress: vaultT4Address,
            nftId: nftId,
            perfectColShares: perfectColWithdrawShares, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
            colToken0MinMax: "-100000000000000000", // -1e17
            colToken1MinMax: "-100000000000000000", // -1e17
            perfectDebtShares: perfectDebtPaybackShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
            debtToken0MinMax: '-1000000000000000000', // very small number
            debtToken1MinMax: '-1000000000000000000', // very small number
            getNftId: 0,
            setIds: Array(9).fill('0')
          }
        ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      const receipt = await tx.wait();
      console.log('receipt done!!');

      const eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
      const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

      const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);
      console.log('log: ', log)

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
      //   parseEther("1000")
      // );
  });

  it("should payback and withdraw max using operate perfect", async function () {
    const nftId = 2297 // Based on block 20995500

    const perfectColWithdrawShares = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
    const perfectDebtPaybackShares = "-57896044618658097711785492504343953926634992332820282019728792003956564819968"

    const spells = [
      {
        connector: connectorName,
        method: "operatePerfectWithIds",
        args: [
        {
          vaultAddress: vaultT4Address,
          nftId: nftId,
          perfectColShares: perfectColWithdrawShares, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
          colToken0MinMax: "-250000000000000000", // -1e17
          colToken1MinMax: "-250000000000000000", // -1e17
          perfectDebtShares: perfectDebtPaybackShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
          debtToken0MinMax: '-1000000000000000000', // very small number
          debtToken1MinMax: '-1000000000000000000', // very small number
          getNftId: 0,
          setIds: Array(9).fill('0')
        }
      ],
      },
    ];

    const tx = await dsaWallet0
      .connect(wallet0)
      .cast(...encodeSpells(spells), wallet1.getAddress());

    const receipt = await tx.wait();
    console.log('receipt done!!');

    const eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
    const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);
    console.log('log: ', log)

    // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   parseEther("1000")
    // );
});
  
  });
});
