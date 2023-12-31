export const connectMapping: Record<string, any> = {
  mainnet: {
    "1INCH-A": "ConnectV2OneInch",
    "1INCH-B": "ConnectV2OneProto",
    "AAVE-V1-A": "ConnectV2AaveV1",
    "AAVE-V2-A": "ConnectV2AaveV2",
    "AUTHORITY-A": "ConnectV2Auth",
    "BASIC-A": "ConnectV2Basic",
    "BASIC-D": "ConnectV2BasicERC4626",
    "COMP-A": "ConnectV2COMP",
    "COMPOUND-A": "ConnectV2Compound",
    "DYDX-A": "ConnectV2Dydx",
    "FEE-A": "ConnectV2Fee",
    "GELATO-A": "ConnectV2Gelato",
    "MAKERDAO-A": "ConnectV2Maker",
    "UNISWAP-A": "ConnectV2UniswapV2",
  },
  polygon: {
    "QUICKSWAP-A": "ConnectV2Paraswap",
    "UniswapV3-v1": "ConnectV2UniswapV3Polygon",
    "Uniswap-V3-Staker-v1.1": "ConnectV2UniswapV3StakerPolygon",
    "Paraswap-v5": "ConnectV2ParaswapV5Polygon",
    "1INCH-V4": "ConnectV2OneInchV4Polygon",
  },
  avalanche: {
    "ZEROEX-A": "ConnectV2ZeroExAvalanche",
  },
};

export const connectors: Record<string, Array<string>> = {
  mainnet: [
    'ConnectV2ZeroEx',
    'ConnectV2ApproveTokens',
    'ConnectV2Auth',
    'ConnectV2Basic',
    'ConnectV2BasicERC721',
    'ConnectV2BasicERC1155',
    'ConnectV2CompoundV3',
    'ConnectV2CompoundV3Rewards',
    'ConnectV2InstaDexSimulation',
    'ConnectV2DSASpell',
    'ConnectV2SwapAggregator',
    'ConnectV2UniswapV3',
    'ConnectV2UniswapV3AutoRouter',
    'ConnectV2UniswapV3Swap',
  ],
  polygon: [
    "QUICKSWAP-A",
    "UniswapV3-v1",
    "Uniswap-V3-Staker-v1.1",
    "Paraswap-v5",
    "1INCH-V4",
  ],
  avalanche: ["ZEROEX-A"],
  base: [
    'ConnectV2ZeroExBase',
    'ConnectV2ApproveTokensBase',
    'ConnectV2AuthBase',
    'ConnectV2BasicBase',
    'ConnectV2BasicERC721Base',
    'ConnectV2BasicERC1155Base',
    'ConnectV2CompoundV3Base',
    'ConnectV2CompoundV3RewardsBase',
    'ConnectV2InstaDexSimulationBase',
    'ConnectV2DSASpellBase',
    'ConnectV2SwapAggregatorBase',
    'ConnectV2UniswapV3Base',
    'ConnectV2UniswapV3AutoRouterBase',
    'ConnectV2UniswapV3SwapBase',
  ],
};
