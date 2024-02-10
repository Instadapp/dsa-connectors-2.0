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

describe("Fluid", function () {
  const connectorName = "FLUID";
  let connector: any;

  let wallet0: Signer, wallet1: Signer, wethHolderSigner: Signer, usdcHolderSigner: Signer;
  let dsaWallet0: any;
  let instaConnectorsV2: any;
  let masterSigner: Signer;
  const setIdMaticUsdc = ethers.BigNumber.from("83478237");
  const setIdWethUsdc = "83478249";
  const setId3 = "85478249";

  const vaultMaticUsdc = "0x2226FFAE044B9fd4ED991aDf20CAACF8E8302510";
  const vaultWethUsdc = "0x10D97a8236624222F681C12Eea4Ddac2BDD0471B";
  const vaultWethMatic = "0x553437CB882E3aFbB67Abd135E067AFB0721fbf1";

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
    it("should deposit 1000 Matic in Fluid", async function () {
      const amtDeposit = parseEther("1000");

      const spells = [
        {
          connector: connectorName,
          method: "operate",
          args: [
            vaultMaticUsdc,
            '0', // new nft
            amtDeposit, // +1000 collateral
            '0', // 0 debt
            '0',
            ['0','0','0','0','0'],
            ['0',setIdMaticUsdc,'0','0','0']
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
    // 1000 matic

    // it("should deposit max Matic in Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc, // matic-usdc vault
    //         0, // setIdMaticUsdc
    //         ethers.constants.MaxUint256, // + max collateral
    //         0, // 0 debt
    //         0,
    //         [0,setIdMaticUsdc,0,0,0],
    //         [0,0,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.lte(
    //     parseEther("1")
    //   );
    // });

    // // 0 matic

    // it("should deposit 10 Weth in Fluid", async function () {
    //   const amtDeposit = parseEther("10");

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethUsdc,
    //         0, // new nft
    //         amtDeposit, // +10 collateral
    //         0, // 0 debt
    //         0,
    //         [0,0,0,0,0],
    //         [0,setIdWethUsdc,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await wethToken.balanceOf(dsaWallet0.address)).to.lte(
    //     parseEther("10")
    //   );
    // });

    // // 10 weth

    // it("should deposit max Weth in Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethUsdc,
    //         0, // get id nft
    //         ethers.constants.MaxUint256, // + max collateral
    //         0, // 0 debt
    //         0,
    //         [0,setIdWethUsdc,0,0,0],
    //         [0,0,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.lte(
    //     parseEther("1")
    //   );
    // });

    // // 0 weth

    // it("Should borrow USDC from Fluid", async function () {
    //   const amtBorrow = parseUnits("100", 6); // 100 USDC

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from getID
    //         0, // 0 collateral
    //         amtBorrow, // +100 debt
    //         0,
    //         [0,0,0,0,0],
    //         [0,0,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await usdcToken.balanceOf(dsaWallet0.address)).to.be.gte(
    //     parseUnits("120", 6)
    //   );
    // });

    // // 120 usdc

    // it("Should deposit WETH and borrow MATIC from Fluid", async function () {
    //   await hre.network.provider.request({
    //     method: "hardhat_impersonateAccount",
    //     params: [wethHolder]
    //   });
  
    //   wethHolderSigner = await ethers.getSigner(wethHolder);
  
    //   await wethToken.connect(wethHolderSigner).transfer(dsaWallet0.address, ethers.utils.parseEther("11"));

    //   const amtDeposit = parseEther("10"); // 10 Weth
    //   const amtBorrow = parseEther("100"); // 100 Matic
      
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethMatic,
    //         0, // new nft id
    //         amtDeposit, // 10 collateral
    //         amtBorrow, // +100 debt
    //         0,
    //         [0,0,0,0,0],
    //         [0,0,0,setId3,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
    //     parseEther("100")
    //   );
    // });

    // // 120 usdc, 100 matic

    // it("Should payback Matic in Fluid", async function () {
    //   const amtPayback = ethers.BigNumber.from(parseEther("50")).mul(-1); // 50 Matic

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethMatic,
    //         0, // nft id from setId3
    //         0, // 0 collateral
    //         amtPayback, // - 50 debt
    //         ethers.BigNumber.from(parseEther("50")),
    //         [0,0,0,0,setId3],
    //         [0,0,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
    //     ethers.utils.parseEther("50")
    //   );
    // });

    // // 120 usdc, 50 matic

    // it("Should payback max Matic in Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethMatic,
    //         0, // nft id from setId3
    //         0, // 0 collateral
    //         ethers.constants.MinInt256, // min Int
    //         ethers.BigNumber.from(parseEther("50")),
    //         [0,0,0,0,0],
    //         [0,0,0,0,0]
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.lte(
    //     ethers.utils.parseEther("1")
    //   );
    // });

    // 120 usdc, 0 matic/////////

    // it("Should payback Usdc in Fluid", async function () {
    //   const amtPayback = ethers.BigNumber.from(parseUnits("60", 6)).mul(-1); // 60 usdc

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from setIdWethUsdc
    //         0, // 0 collateral
    //         amtPayback, // - 60 debt
    //         dsaWallet0.address,
    //         setIdMaticUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await usdcToken.balanceOf(dsaWallet0.address)).to.be.lte(parseUnits("60", 6));
    // });

    // // 60 usdc, 0 matic

    // it("Should payback max Matic in Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from setIdWethUsdc
    //         0, // 0 collateral
    //         ethers.constants.MinInt256, // min Int
    //         dsaWallet0.address,
    //         setIdMaticUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());
    //   await tx.wait();
      
    //   expect(await usdcToken.balanceOf(dsaWallet0.address)).to.be.lte(parseUnits("1", 6));
    // });

    // // 0 usdc, 0 matic

    // it("Should withdraw Matic from Fluid", async function () {
    //   const amt = ethers.BigNumber.from(parseEther("100")).mul(-1); // 100 Matic

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from setIdMaticUsdc
    //         amt, // - 100 collateral
    //         0, // 0 debt
    //         dsaWallet0.address,
    //         setIdMaticUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
    //     parseEther("100")
    //   );
    // });

    // // 0 usdc, 100 matic

    // it("Should withdraw max Matic from Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultMaticUsdc,
    //         0, // nft id from setIdMaticUsdc
    //         ethers.constants.MinInt256, // min integer value
    //         0, // 0 debt
    //         dsaWallet0.address,
    //         setIdMaticUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
    //     parseEther("1000")
    //   );
    // });

    // // 0 usdc, 1000 matic

    // it("Should withdraw WETH from Fluid", async function () {
    //   const amt = ethers.BigNumber.from(parseEther("10")).mul(-1); // 10 Weth

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethUsdc,
    //         0, // nft id from setIdWethUsdc
    //         amt, // -10 collateral
    //         0, // 0 debt
    //         dsaWallet0.address,
    //         setIdWethUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await wethToken.balanceOf(dsaWallet0.address)).to.eq(
    //     parseEther("10")
    //   );
    // });

    // // 0 usdc, 1000 matic, 10 weth

    // it("Should withdraw max WETH from Fluid", async function () {
    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "operate",
    //       args: [
    //         vaultWethUsdc,
    //         0, // nft id from setIdWethUsdc
    //         ethers.constants.MinInt256, // min integer value
    //         0, // 0 debt
    //         dsaWallet0.address,
    //         setIdWethUsdc,
    //         0
    //       ],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.getAddress());

    //   await tx.wait();

    //   expect(await ethers.provider.getBalance(dsaWallet0.address)).to.eq(
    //     parseEther("29")
    //   );
    // });

    // 0 usdc, 1000 matic, 30 weth

    // todo: add a (payback and withdraw case)
  });
});
