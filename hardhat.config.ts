import "@nomicfoundation/hardhat-ethers"
import "@nomicfoundation/hardhat-verify"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import "dotenv/config"
import "./tasks/addUpkeeps"
import "./tasks/approveLinkToRegistrar"
import "./tasks/dismantleStation"
import "./tasks/forceStationRefuel"
import "./tasks/forceUpkeepRefuel"
import "./tasks/initializeStation"
import "./tasks/migrateUpkeeps"
import "./tasks/pauseUpkeeps"
import "./tasks/recoverERC20"
import "./tasks/registerUpkeep"
import "./tasks/removeUpkeep"
import "./tasks/setForwarder"
import "./tasks/setRefuelConfig"
import "./tasks/setRegisterUpkeepSelector"
import "./tasks/setRegistrar"
import "./tasks/unpauseUpkeeps"
import "./tasks/unregisterUpkeep"
import "./tasks/withdrawUpkeeps"
import importToml from "import-toml"
import { HardhatUserConfig } from "hardhat/config"

const foundryConfig = importToml.sync("foundry.toml")

const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHEREUM_RPC = "https://eth.llamarpc.com" || process.env.ETHEREUM_RPC
const ETHEREUM_SEPOLIA_RPC = "https://rpc.sepolia.org" || process.env.ETHEREUM_SEPOLIA_RPC
const BASE_RPC = "https://mainnet.base.org" || process.env.BASE_RPC
const BASE_SEPOLIA_RPC = "https://sepolia.base.org" || process.env.BASE_SEPOLIA_RPC
const POLYGON_MAINNET_RPC = "https://rpc-mainnet.maticvigil.com" || process.env.POLYGON_MAINNET_RPC
const POLYGON_AMOY_RPC = "https://rpc-amoy.polygon.technology" || process.env.POLYGON_AMOY_RPC
const AVALANCHE_C_CHAIN_RPC = "https://api.avax.network/ext/bc/C/rpc" || process.env.AVALANCHE_C_CHAIN_RPC
const AVALANCHE_FUJI_RPC = "https://api.avax-test.network/ext/bc/C/rpc" || process.env.AVALANCHE_FUJI_RPC
const ARBITRUM_ONE_RPC = "https://arb1.arbitrum.io/rpc" || process.env.ARBITRUM_ONE_RPC
const ARBITRUM_SEPOLIA_RPC = "https://sepolia-rollup.arbitrum.io/rpc" || process.env.ARBITRUM_TESTNET_RPC
const BSC_RPC = "https://bsc-dataseed4.binance.org" || process.env.BSC_RPC
const BSC_TESTNET_RPC = "https://data-seed-prebsc-2-s1.binance.org:8545" || process.env.BSC_TESTNET_RPC
const FANTOM_RPC = "https://rpcapi.fantom.network" || process.env.FANTOM_RPC
const FANTOM_TESTNET_RPC = "https://rpc.testnet.fantom.network" || process.env.FANTOM_TESTNET_RPC
const OPTIMISM_RPC = "https://mainnet.optimism.io" || process.env.OPTIMISM_RPC
const OPTIMISM_SEPOLIA_RPC = "https://sepolia.optimism.io" || process.env.OPTIMISM_SEPOLIA_RPC
const GNOSIS_RPC = "https://rpc.gnosis.gateway.fm" || process.env.GNOSIS_RPC
const GNOSIS_TESTNET_RPC = "https://rpc.chiado.gnosis.gateway.fm" || process.env.GNOSIS_TESTNET_RPC

const config: HardhatUserConfig = {
    etherscan: {
        apiKey: {
            mainnet: process.env.ETHERSCAN_API_KEY,
            sepolia: process.env.ETHERSCAN_API_KEY,
            polygon: process.env.POLYGONSCAN_API_KEY,
            polygonAmoy: process.env.POLYGONSCAN_API_KEY,
            base: process.env.BASESCAN_API_KEY,
            baseSepolia: process.env.BASESCAN_API_KEY,
            avalanche: process.env.SNOWTRACE_API_KEY,
            avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY,
            arbitrumOne: process.env.ARBISCAN_API_KEY,
            arbitrumSepolia: process.env.ARBISCAN_API_KEY,
            bsc: process.env.BSCSCAN_API_KEY,
            bscTestnet: process.env.BSCSCAN_API_KEY,
            opera: process.env.FTMSCAN_API_KEY,
            ftmTestnet: process.env.FTMSCAN_API_KEY,
            optimisticEthereum: process.env.OPTIMISM_ETHERSCAN_KEY,
            optimisticSepolia: process.env.OPTIMISM_ETHERSCAN_KEY,
            gnosis: process.env.GNOSISSCAN_API_KEY,
            chiado: process.env.GNOSISSCAN_API_KEY
        },
        customChains: [
            {
              network: "optimisticSepolia",
              chainId: 11155420,
              urls: {
                apiURL: "https://sepolia.optimism.io",
                browserURL: "https://sepolia-optimistic.etherscan.io"
              }
            }
        ]
    },
    networks: {
        mainnet: {
            url: ETHEREUM_RPC,
            chainId: 1,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        sepolia: {
            url: ETHEREUM_SEPOLIA_RPC,
            chainId: 11155111,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
        base: {
            url: BASE_RPC,
            chainId: 8453,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        baseSepolia: {
            url: BASE_SEPOLIA_RPC,
            chainId: 84532,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
        polygon: {
            url: POLYGON_MAINNET_RPC,
            chainId: 137,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        polygonAmoy: {
            url: POLYGON_AMOY_RPC,
            chainId: 80002,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
        avalanche: {
            url: AVALANCHE_C_CHAIN_RPC,
            chainId: 43114,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        avalancheFujiTestnet: {
            url: AVALANCHE_FUJI_RPC,
            chainId: 43113,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
        arbitrumOne: {
            url: ARBITRUM_ONE_RPC,
            chainId: 42161,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY],
        },
        arbitrumSepolia: {
            url: ARBITRUM_SEPOLIA_RPC,
            chainId: 421614,
            live: true,
            saveDeployments: true,
            gasMultiplier: 2,
            accounts: [PRIVATE_KEY],
        },
        bsc: {
            url: BSC_RPC,
            chainId: 56,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        bscTestnet: {
            url: BSC_TESTNET_RPC,
            chainId: 97,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        opera: {
            url: FANTOM_RPC,
            chainId: 250,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        ftmTestnet: {
            url: FANTOM_TESTNET_RPC,
            chainId: 4002,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        optimisticEthereum: {
            url: OPTIMISM_RPC,
            chainId: 10,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        optimisticSepolia: {
            url: OPTIMISM_SEPOLIA_RPC,
            chainId: 11155420,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        gnosis: {
            url: GNOSIS_RPC,
            chainId: 100,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        },
        chiado: {
            url: GNOSIS_TESTNET_RPC,
            chainId: 10200,
            live: true,
            saveDeployments: true,
            accounts: [PRIVATE_KEY]
        }
    },
    solidity: {
        version: foundryConfig.profile.default.solc_version,
        settings: {
            viaIR: foundryConfig.profile.default.via_ir,
            optimizer: {
                enabled: true,
                runs: foundryConfig.profile.default.optimizer_runs,
            },
        },
    },
    namedAccounts: {
        deployer: 0,
    },
}

export default config
