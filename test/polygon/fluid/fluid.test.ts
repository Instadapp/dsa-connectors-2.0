import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2FluidPolygon, ConnectV2FluidPolygon__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { constants } from "../../../scripts/constant/constant";
import { network, ethers } from "hardhat";
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

describe("Fluid", function () {
  const connectorName = "FLUID";
  let connector: any;

  let wallet0: Signer, wallet1: Signer, wethHolderSigner: Signer, usdcHolderSigner: Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;
  const setIdMaticUsdc = "83478237";
  const setIdWethUsdc = "83478249";
  const setId3 = "85478249";
  const setId4 = "55478249";

  const vaultMaticUsdc = "0xAf047A21CE590B36FE894dd6fa350b57Ea5Cb0aa";
  const vaultWethUsdc = "0xEad5D80db075a905c141b37cE903d621952eA3f6";
  const vaultWethMatic = "0x23918014AF7610e31e58A9DC9f9A7DdbfcA4087e";
  const vaultUsdcMatic = "0x6395Ddb6161CeF6e64D4c027fbBa26CC76F18148";

  const wethHolder = "0xdeD8C5159CA3673f543D0F72043E4c655b35b96A";
  const usdcHolder = "0xA67EFB69A4f58F568aAB1b9d51110102985835b0";

  const WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  const USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

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

  const wethToken = new ethers.Contract(WETH, erc20Abi);
  const usdcToken = new ethers.Contract(USDC, erc20Abi);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 53327050,
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
      contractArtifact: ConnectV2FluidPolygon__factory,
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

    it("Deposit 2000 Matic into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: parseEther("2000"),
      });

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("2000"));

    });

    it("Deposit 20 Weth into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: wethHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wethHolder]
      });
  
      wethHolderSigner = await ethers.getSigner(wethHolder);
  
      await wethToken.connect(wethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("20"));

      expect(await wethToken.connect(wethHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("20"));
    });

    it("Deposit 20 Usdc into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: usdcHolder,
        value: parseEther("200"),
      });

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [usdcHolder]
      });
  
      usdcHolderSigner = await ethers.getSigner(usdcHolder);
  
      await usdcToken.connect(usdcHolderSigner).transfer(dsaWallet0.address, parseUnits("20", 6));

      expect(await usdcToken.connect(usdcHolderSigner).balanceOf(dsaWallet0.address)).to.be.gte(parseUnits("20", 6));
    });
  });

  // 2000 matic, 20 weth, 20 usdc

  describe("Main", function () {
    it("should deposit 1000 Matic in Fluid in MATIC-USDC", async function () {
      const amtDeposit = parseEther("1000");

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultMaticUsdc,
            '0', // new nft
            amtDeposit, // +1000 collateral
            '0', // 0 debt
            '0',
            ['0', '0', '0', '0', '0'],
            [setIdMaticUsdc, '0', '0', '0', '0'] // set NFT ID of position
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
        parseEther("1000")
      );
    });
    // 1000 matic, 20 weth, 20 usdc

    it("should deposit max Matic in Fluid in MATIC-USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultMaticUsdc, // matic-usdc vault
            0, // NFT ID from setIdMaticUsdc
            ethers.constants.MaxInt256, // + max collateral
            0, // 0 debt
            0,
            [setIdMaticUsdc, '0', '0', '0', '0'],
            [setIdMaticUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.lte(
        parseEther("1")
      );
    });

    // // 0 matic, 20 weth, 20 usdc

    it("should deposit 9 Weth in Fluid in WETH-USDC", async function () {
      const amtDeposit = parseEther("9");

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // New nft for WETH-USDC market
            amtDeposit, // +10 collateral
            0, // 0 debt
            0, // 0 repay
            ['0', '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.lte(
        parseEther("11")
      );
    });

    // // 0 matic, 11 weth, 20 usdc

    it("should deposit max Weth in Fluid in WETH-USDC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // get nft id
            ethers.constants.MaxInt256, // + max collateral
            0, // 0 debt
            0,
            [setIdWethUsdc, '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.lte(
        parseEther("1")
      );
    });

    // // 0 matic, 0 weth, 20 usdc

    it("should deposit 10 USDC in Fluid in USDC-MATIC", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultUsdcMatic,
            0, // get nft id
            parseUnits("10", 6), // + max collateral
            0, // 0 debt
            0
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.lte(
        parseEther("10")
      );
    });

    // // 0 matic, 0 weth, 10 usdc

    it("Should borrow 0.1 USDC from Fluid in WETH-USDC", async function () {
      const amtBorrow = parseUnits("0.1", 6); // 0.1 USDC

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // nft ID from getID
            0, // 0 collateral
            amtBorrow, // +0.1 debt
            0,
            [setIdWethUsdc, '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.gte(
        parseUnits("10", 6)
      );
    });

    // // 0 matic, 0 weth, 10.1 usdc

    it("Should deposit 5 WETH and borrow 0.1 MATIC from Fluid in WETH-MATIC", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wethHolder]
      });
  
      wethHolderSigner = await ethers.getSigner(wethHolder);
  
      await wethToken.connect(wethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("10"));

      const amtDeposit = parseEther("5"); // 5 Weth
      const amtBorrow = parseEther("0.1"); // 100 Matic
      
      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethMatic,
            0, // new nft id
            amtDeposit, // 10 collateral
            amtBorrow, // +100 debt
            0,
            ['0', '0', '0', '0', '0'],
            [setId3, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("0.099")
      );

      expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.lte(
        parseEther("6")
      );
    });

    // // 0.1 matic, 5 weth, 10.1 usdc

    it("Should deposit 5 WETH and borrow 0.1 MATIC from Fluid in WETH-MATIC", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wethHolder]
      });
  
      wethHolderSigner = await ethers.getSigner(wethHolder);
  
      await wethToken.connect(wethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("10"));

      const amtDeposit = parseEther("5"); // 5 Weth
      const amtBorrow = parseEther("0.1"); // 0.1 Matic
      
      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethMatic,
            0, // new nft id
            amtDeposit, // 10 collateral
            amtBorrow, // +0.1 debt
            0,
            ['0', '0', '0', '0', '0'],
            [setId4, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        parseEther("0.19")
      );

      expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.lte(
        parseEther("11")
      );
    });

    // // 0.2 matic, 10 weth, 10.1 usdc

    it("Should payback 0.04 Matic in Fluid in WETH-MATIC", async function () {
      const amtPayback = new BigNumber(parseEther("0.04").toString()).multipliedBy(-1); // 0.04 Matic

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethMatic,
            0, // nft id from setId3
            0, // 0 collateral
            amtPayback, // - 0.04 debt
            new BigNumber(parseEther("0.04").toString()),
            [setId3, '0', '0', '0', '0'],
            [setId3, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
        ethers.utils.parseEther("0.2")
      );
    });

    // // 0.16 matic, 10 weth, 10.1 usdc

    // it("Should payback max Matic in Fluid in WETH-MATIC", async function () {
    //   await wallet0.sendTransaction({
    //     to: dsaWallet0.address,
    //     value: parseEther("1"),
    //   });

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operateWithIds",
    //       args: [
    //         vaultWethMatic,
    //         0, // nft id from setId3
    //         0, // 0 collateral
    //         ethers.constants.MinInt256, // min Int
    //         new BigNumber(parseEther("0.7").toString()),
    //         [setId3, '0', '0', '0', '0'],
    //         ['0', '0', '0', '0', '0']
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   // expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
    //   //   ethers.utils.parseEther("0.97")
    //   // );
    // });

    // // 0.96 matic, 10 weth, 10.1 usdc

    it("Should payback 0.05 Usdc in Fluid in WETH-USDC", async function () {
      const amtPayback = new BigNumber(parseUnits("0.05", 6).toString()).multipliedBy(-1); // 0.05 usdc

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // nft id from setIdWethUsdc
            0, // 0 collateral
            amtPayback, // - 0.05 debt
            new BigNumber(parseUnits("0.05", 6).toString()),
            [setIdWethUsdc, '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());
      await tx.wait();
      
      expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.lte(parseUnits("10.05", 6));
    });

    // // 0.96 matic, 10 weth, 10.05 usdc

    it("Should withdraw 100 Matic from Fluid in MATIC-USDC", async function () {
      const amt = new BigNumber(parseEther("100").toString()).multipliedBy(-1); // 100 Matic

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultMaticUsdc,
            0, // nft id from setIdMaticUsdc
            amt, // - 100 collateral
            0, // 0 debt
            0,
            [setIdMaticUsdc, '0', '0', '0', '0'],
            [setIdMaticUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.gte(
        parseEther("100")
      );
    });

    // // 100.96 matic, 10 weth, 10.05 usdc

    // it("Should withdraw max Matic from Fluid in MATIC-USDC", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operateWithIds",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from setIdMaticUsdc
    //         ethers.constants.MinInt256, // min integer value
    //         0, // 0 debt
    //         0,
    //         [setIdMaticUsdc, '0', '0', '0', '0'],
    //         ['0', '0', '0', '0', '0']
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
    //     parseEther("2000")
    //   );
    // });

    // // 2000.96 matic, 10 weth, 10.05 usdc

    it("Should withdraw 0.4 WETH from Fluid in WETH-USDC", async function () {
      const amt = new BigNumber(parseEther("0.4").toString()).multipliedBy(-1); // 1 Weth

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // nft id from setIdWethUsdc
            amt, // -1 collateral
            0, // 0 debt
            0,
            [setIdWethUsdc, '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      // expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.gte(
      //   parseEther("11")
      // );
    });

    // // 2000.96 matic, 11 weth, 10.05 usdc

    it("Should payback 0.02 and withdraw 0.5 WETH from Fluid in WETH-USDC", async function () {
      const amt = new BigNumber(parseEther("0.5").toString()).multipliedBy(-1); // 1 Weth
      const paybackAmt = new BigNumber(parseUnits("0.02", 6).toString()).multipliedBy(-1); // 1 Weth

      const spells = [
        {
          connector: connectorName,
          method: "operateWithIds",
          args: [
            vaultWethUsdc,
            0, // nft id from setIdWethUsdc
            amt, // -1 collateral
            paybackAmt, // 0 debt
            new BigNumber(parseUnits("0.03", 6).toString()),
            [setIdWethUsdc, '0', '0', '0', '0'],
            [setIdWethUsdc, '0', '0', '0', '0']
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.getAddress());

      await tx.wait();

      // expect(await wethToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.gte(
      //   parseEther("12")
      // );

      // expect(await usdcToken.connect(wallet0).balanceOf(dsaWallet0.address)).to.gte(
      //   parseEther("11")
      // );
    });

    // todo: add a (payback and withdraw case)
  });
});
