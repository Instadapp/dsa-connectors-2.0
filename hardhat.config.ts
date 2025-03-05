// import "@nomiclabs/hardhat-waffle";
// import "@nomiclabs/hardhat-ethers";
// import "@nomiclabs/hardhat-etherscan";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-web3";

import "@typechain/hardhat";
import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import Web3 from "web3";
import { network } from "hardhat";
import bigNumber from "bignumber.js";
import "./scripts/tests/run_test_through_cmd";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  hardhat: 31337,
  mainnet: 1,
  avalanche: 43114,
  polygon: 137,
  arbitrum: 42161,
  optimism: 10,
  fantom: 250,
  base: 8453,
};

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_API_KEY in a .env file");
}

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const mnemonic = process.env.MNEMONIC ?? "test test test test test test test test test test test junk";

const networkGasPriceConfig: Record<string, number> = {
  mainnet: 7.1,
  polygon: 46,
  avalanche: 2,
  arbitrum: 1,
  optimism: 0.01,
  fantom: 210,
  base: 0.05
};

function createConfig(network: string) {
  return {
    url: getNetworkUrl(network),
    accounts: !!PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : { mnemonic },
    gasPrice: new bigNumber(networkGasPriceConfig[network]).times(1e9).toNumber() // Update the mapping above
  };
}

function getNetworkUrl(networkType: string) {
  if (networkType === "avalanche") return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon") return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum") return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "optimism") return `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "fantom") return `https://rpc.ftm.tools/`;
  else if (networkType === "base") return `https://1rpc.io/base`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: any = {
  solidity: {
    compilers: [
      {
        version: "0.8.27",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.6.0"
      },
      {
        version: "0.6.2"
      },
      {
        version: "0.6.5"
      }
    ]
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic
      },
      chainId: chainIds.hardhat,
      forking: {
        url: String(getNetworkUrl(String(process.env.networkType)))
      }
    },
    mainnet: createConfig("mainnet"),
    polygon: createConfig("polygon"),
    avalanche: createConfig("avalanche"),
    arbitrum: createConfig("arbitrum"),
    optimism: createConfig("optimism"),
    fantom: createConfig("fantom"),
    base: createConfig("base")
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test"
  },
  etherscan: {
    apiKey: {
      mainnet: String(process.env.MAIN_ETHSCAN_KEY),
      optimisticEthereum: String(process.env.OPT_ETHSCAN_KEY),
      polygon: String(process.env.POLY_ETHSCAN_KEY),
      arbitrumOne: String(process.env.ARB_ETHSCAN_KEY),
      avalanche: String(process.env.AVAX_ETHSCAN_KEY),
      opera: String(process.env.FTM_ETHSCAN_KEY),
      base: String(process.env.BASE_ETHSCAN_KEY),
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
         apiURL: "https://api.basescan.org/api",
         browserURL: "https://basescan.org"
        }
      }
    ]
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5"
  },
  mocha: {
    timeout: 10000 * 1000 // 10,000 seconds
  }
  // tenderly: {
  //   project: process.env.TENDERLY_PROJECT,
  //   username: process.env.TENDERLY_USERNAME,
  // },
};

export default config;
