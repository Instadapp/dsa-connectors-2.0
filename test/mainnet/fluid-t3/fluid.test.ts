import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2FluidVaultT3, ConnectV2FluidVaultT3__factory } from "../../../typechain";
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
  let nftId = "2385";
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;

  const vaultT3Address = "0x221E35b5655A1eEB3C42c4DeFc39648531f6C9CF";

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
            blockNumber: 21067660,
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
      contractArtifact: ConnectV2FluidVaultT3__factory,
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

    it("Deposit 1 Wsteth into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: wstethHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wstethHolder]
      });
  
      wstethHolderSigner = await ethers.getSigner(wstethHolder);
  
      await wstethToken.connect(wstethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("1"));

      expect(await wstethToken.connect(wstethHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("1"));
    });
  });

  // 20 wsteth 20 eth

  describe("Main", function () {
    // it("should deposit and borrow using operate perfect", async function () {
    //     const newCol = parseEther("0.5"); // 5e17
    //     const perfectDebtShares = parseEther("0.2"); // 2e17
  
    //     const spells = [
    //       {
    //         connector: connectorName,
    //         method: "operatePerfectWithIds",
    //         args: [
    //         {
    //           vaultAddress: vaultT3Address,
    //           nftId: '0',
    //           newCol: newCol, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
    //           perfectDebtShares: perfectDebtShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
    //           debtToken0MinMax: '1', // very small number
    //           debtToken1MinMax: '1', // very small number
    //           getNftId: 0,
    //           setIds: Array(7).fill('0')
    //         }
    //       ],
    //       },
    //     ];
  
    //     // Execute the cast transaction with encoded spells
    //     const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), await wallet1.getAddress());

    //   // Wait for the transaction to be mined
    //   const receipt = await tx.wait();
    //   console.log('Transaction receipt received.');  
  
    //     // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //     //   parseEther("1000")
    //     // );
    // });

    // it("should payback and withdraw using operate perfect", async function () {
    //   const newCol = "-200000000000000000"; // 0.2
    //   const perfectDebtPaybackShares = "-100000000000000000"; // 0.1

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultT3Address,
    //         nftId: nftId,
    //         newCol: newCol, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
    //         perfectDebtShares: perfectDebtPaybackShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
    //         debtToken0MinMax: '-1000000000000000000', // very small number
    //         debtToken1MinMax: '-1000000000000000000', // very small number
    //         getNftId: 0,
    //         setIds: Array(7).fill('0')
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();
    //   console.log('receipt done!!');

    //   const eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);
    //   console.log('log: ', log)

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // it("should payback max and withdraw using operate perfect", async function () {
    //   // const newCol = new BigNumber("57896044618658097711785492504343953926634992332820282019728792003956564819968")
    //   // const perfectDebtPaybackShares = new BigNumber("57896044618658097711785492504343953926634992332820282019728792003956564819968")
    //   const newCol = ethers.constants.MinInt256
    //   const perfectDebtPaybackShares = ethers.constants.MinInt256

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultT3Address,
    //         nftId: "2395",
    //         newCol: newCol,
    //         perfectDebtShares: perfectDebtPaybackShares,
    //         debtToken0MinMax: '-100000000000000000000000',
    //         debtToken1MinMax: '-100000000000000000000000',
    //         getNftId: 0,
    //         setIds: Array(7).fill('0')
    //       }
    //     ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   const receipt = await tx.wait();
    //   console.log('receipt done!!');

    //   const eventName = "LogOperatePerfectWithIds(address,uint256,int256,int256,int256,int256,int256,int256,uint256,uint256[])";
    //   const eventSignatureHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(eventName));

    //   const log = receipt.logs.find((log: { topics: string[]; }) => log.topics[0] === eventSignatureHash);
    //   console.log('log: ', log)

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

  //   it("should deposit max and borrow using operate perfect", async function () {
  //     const nftId = 2297 // Based on block 20995500
  //     // const perfectColShares = new BigNumber("57896044618658097711785492504343953926634992332820282019728792003956564819968");
  //     const newCol = ethers.constants.MaxInt256
  //     const perfectDebtShares = parseEther("1"); // 2e17

  //     const spells = [
  //       {
  //         connector: connectorName,
  //         method: "operatePerfectWithIds",
  //         args: [
  //         {
  //           vaultAddress: vaultT3Address,
  //           nftId: nftId,
  //           newCol: newCol,
  //           perfectDebtShares: perfectDebtShares, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
  //           debtToken0MinMax: '1', // very small number
  //           debtToken1MinMax: '1', // very small number
  //           getNftId: 0,
  //           setIds: Array(7).fill('0')
  //         }
  //       ],
  //       },
  //     ];

  //     // Execute the cast transaction with encoded spells
  //     const tx = await dsaWallet0
  //     .connect(wallet0)
  //     .cast(...encodeSpells(spells), await wallet1.getAddress());

  //     // Wait for the transaction to be mined
  //     const receipt = await tx.wait();
  //     console.log('Transaction receipt received.');  

  //     // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
  //     //   parseEther("1000")
  //     // );
  // });

    it("should deposit and borrow using operate", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
          {
            vaultAddress: vaultT3Address,
            nftId: 0,
            newCol: parseEther("0.01"),
            newDebtToken0: parseUnits("0.2", "6"),
            newDebtToken1: parseUnits("0.2", "6"),
            debtSharesMinMax: parseEther("1"),
            getIds: Array(7).fill('0'),
            setIds: Array(7).fill('0')
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
    // console.log('Transaction receipt received.');  

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
      //   parseEther("1000")
      // );
    });

    it("should payback and withdraw using operate", async function () {
      const newCol = "-1000000000000000"; // 0.1
      const paybackAmount0 = "-100000"; // 0.1
      const paybackAmount1 = "-100000"; // 0.1

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
          {
            vaultAddress: vaultT3Address,
            nftId: "2395",
            newCol: newCol,
            newDebtToken0: paybackAmount0,
            newDebtToken1: paybackAmount1,
            debtSharesMinMax: "-10000000000000000",
            getIds: Array(7).fill('0'),
            setIds: Array(7).fill('0')
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

  //   it("should deposit max and borrow using operate", async function () {
  //     const nftId = 2297 // Based on block 20995500
  //     // const depositAmount = ethers.constants.MaxInt256;
  //     const depositAmount = new BigNumber("57896044618658097711785492504343953926634992332820282019728792003956564819967")
  //     // console.log('ethers.constants.MaxInt256: ', ethers.constants.MaxInt256);
  //     const borrowAmount0 = parseEther("1"); // 1e17
  //     const borrowAmount1 = parseEther("0.5"); // 1e17

  //     const spells = [
  //           {
  //             connector: connectorName,
  //             method: "operateWithIds",
  //             args: [
  //             {
  //               vaultAddress: vaultT3Address,
  //               nftId: nftId,
  //               newCol: "10000000000000000000",
  //               newDebtToken0: parseEther("0.2"),
  //               newDebtToken1: parseEther("0.2"),
  //               debtSharesMinMax: parseEther("1"),
  //               getIds: Array(7).fill('0'),
  //               setIds: Array(7).fill('0')
  //             }
  //           ],
  //           },
  //         ];

  //     // Execute the cast transaction with encoded spells
  //     const tx = await dsaWallet0
  //     .connect(wallet0)
  //     .cast(...encodeSpells(spells), await wallet1.getAddress());

  //     // Wait for the transaction to be mined
  //     const receipt = await tx.wait();
  //     console.log('Transaction receipt received.');  

  //     // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
  //     //   parseEther("1000")
  //     // );
  //   });
  });
});
