import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2FluidVaultT2, ConnectV2FluidVaultT2__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { constants } from "../../../scripts/constant/constant";
import { network, ethers } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

describe("Fluid Dex", function () {
  const connectorName = "FLUID-DEX";
  let connector: any;

  let wallet0: Signer, wallet1: Signer, wbtcHolderSigner: Signer, cbbtcHolderSigner: Signer;
  let nftId = "2385";
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;

  // WBTC-cbBTC smart collateral & USDT debt
  const vaultT2Address = "0xf7FA55D14C71241e3c970E30C509Ff58b5f5D557";

  const wbtcHolder = "0xbE6d2444a717767544a8b0Ba77833AA6519D81cD";
  const WBTC = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";

  const cbbtcHolder = "0xD48573cDA0fed7144f2455c5270FFa16Be389d04";
  const CBBTC = "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf";

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

  const wbtcToken = new ethers.Contract(WBTC, erc20Abi);
  const cbbtcToken = new ethers.Contract(CBBTC, erc20Abi);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 21066770,
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
      contractArtifact: ConnectV2FluidVaultT2__factory,
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

    it("Deposit 0.001 Wbtc into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: wbtcHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wbtcHolder]
      });
  
      wbtcHolderSigner = await ethers.getSigner(wbtcHolder);
  
      await wbtcToken.connect(wbtcHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseUnits("0.01", 8));

      expect(await wbtcToken.connect(wbtcHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseUnits("0.01", 8));
    });

    it("Deposit 0.001 cbBTC into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: cbbtcHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [cbbtcHolder]
      });
  
      cbbtcHolderSigner = await ethers.getSigner(cbbtcHolder);
  
      await cbbtcToken.connect(cbbtcHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseUnits("0.01", 8));

      expect(await cbbtcToken.connect(cbbtcHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseUnits("0.01", 8));
    });

    // it("Deposit 1 Eth into DSA wallet", async function () {
    //   await wallet0.sendTransaction({
    //     to: dsaWallet0.address,
    //     value: parseEther("1"),
    //   });
    //   // expect(await wstethToken.connect(wbtcHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("20"));
    // });
  });

  // 20 wsteth 20 eth

  describe("Main", function () {
    it("should deposit and borrow using operate perfect", async function () {
        const perfectColShares = parseEther("0.001"); // 5e17
        const newDebt = parseUnits("0.2", "6"); // 2e17
        const repayApproveAmt = parseUnits("0.2", "6"); // 2e17

        const spells = [
          {
            connector: connectorName,
            method: "operatePerfectWithIds",
            args: [
            {
              vaultAddress: vaultT2Address,
              nftId: '0',
              perfectColShares: perfectColShares, // (this will deposit about ~0.3 ETH & ~0.3 ETH worth of wstETH)
              colToken0MinMax: parseEther("1"), // 1e21
              colToken1MinMax: parseEther("1"), // 1e21
              newDebt: newDebt, // (this will payabck about ~0.3 ETH & ~0.3 ETH worth of wstETH)
              repayApproveAmt: repayApproveAmt, // very small number
              getNftId: 0,
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
      console.log('Transaction receipt received.');  
  
        // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
        //   parseEther("1000")
        // );
    });

    // it("should payback and withdraw using operate perfect", async function () {
    //   const perfectColWithdrawShares = "-100000000000000"; // 0.0001
    //   const newDebt = "-100000"; // 0.1
    //   const repayApproveAmt = "100000"; // 0.1

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultT2Address,
    //         nftId: "2385",
    //         perfectColShares: perfectColWithdrawShares,
    //         colToken0MinMax: "-1", // -1e17
    //         colToken1MinMax: "-1", // -1e17
    //         newDebt: newDebt,
    //         repayApproveAmt: repayApproveAmt,
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

    // it("should deposit max and borrow using operate perfect", async function () {
    //   // const perfectColShares = new BigNumber("57896044618658097711785492504343953926634992332820282019728792003956564819968");
    //   const perfectColShares = ethers.constants.MaxInt256
    //   const newDebt = parseUnits("1", "6");
    //   const repayApproveAmt = parseUnits("1", "6");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operatePerfectWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultT2Address,
    //         nftId: 0,
    //         perfectColShares: perfectColShares,
    //         colToken0MinMax: parseEther("2"),
    //         colToken1MinMax: parseEther("2"),
    //         newDebt: newDebt,
    //         repayApproveAmt: repayApproveAmt,
    //         getNftId: 0,
    //         setIds: Array(7).fill('0')
    //       }
    //     ],
    //     },
    //   ];

    //   // Execute the cast transaction with encoded spells
    //   const tx = await dsaWallet0
    //   .connect(wallet0)
    //   .cast(...encodeSpells(spells), await wallet1.getAddress());

    //   // Wait for the transaction to be mined
    //   const receipt = await tx.wait();
    //   console.log('Transaction receipt received.');  

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    // it("should deposit and borrow using operate", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operateWithIds",
    //       args: [
    //       {
    //         vaultAddress: vaultT2Address,
    //         nftId: '0',
    //         newColToken0: parseEther("0.005"),
    //         newColToken1: parseEther("0.005"),
    //         colSharesMinMax: parseEther("0.1"),
    //         newDebt: parseUnits("0.2", "6"),
    //         repayApproveAmt: parseUnits("0.2", "6"),
    //         getIds: Array(7).fill('0'),
    //         setIds: Array(7).fill('0')
    //       }
    //     ],
    //     },
    //   ];

    //   // Execute the cast transaction with encoded spells
    //   const tx = await dsaWallet0
    //   .connect(wallet0)
    //   .cast(...encodeSpells(spells), await wallet1.getAddress());

    // // Wait for the transaction to be mined
    // const receipt = await tx.wait();
    // // console.log('Transaction receipt received.');  

    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
    //   //   parseEther("1000")
    //   // );
    // });

    it("should payback and withdraw using operate", async function () {
      const withdrawAmount0 = "-10000"; // 0.0001
      const withdrawAmount1 = "-10000"; // 0.0001
      const newDebt = "-100000"; // 0.1
      const repayApproveAmt = "100000"; // 0.1

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
          {
            vaultAddress: vaultT2Address,
            nftId: nftId,
            newColToken0: withdrawAmount0,
            newColToken1: withdrawAmount1,
            colSharesMinMax: "-100000000000000000000000000000",
            newDebt: newDebt,
            repayApproveAmt: repayApproveAmt,
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

    it("should deposit max and borrow using operate", async function () {
      const spells = [
            {
              connector: connectorName,
              method: "operateWithIds",
              args: [
              {
                vaultAddress: vaultT2Address,
                nftId: nftId,
                newColToken0: "100000",
                newColToken1: "100000",
                colSharesMinMax: "1",
                newDebt: parseUnits("0.2", "6"),
                repayApproveAmt: parseUnits("0.2", "6"),
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
      console.log('Transaction receipt received.');  

      // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
      //   parseEther("1000")
      // );
    });
  });
});
