// npm i @nomiclabs/hardhat-ethers
require('dotenv').config()
require('@nomicfoundation/hardhat-toolbox')
require('@openzeppelin/hardhat-upgrades')
require('solidity-docgen')

module.exports = {
  docgen: {
    outputFormat: 'md',
    path: './docs', // Output directory for the generated documentation
    clear: true, // Clear the output directory before generating documentation
    runOnCompile: false, // Generate documentation automatically when you compile
    pages: 'files' /*'single': all items in one page
                    * 'items': one page per item
                   'files': one page per input Solidity file  */,
  },

  defaultNetwork: 'localhost',
  networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      chainId: 1337,
    },
    ganache: {
      url: process.env.GANACHE_LOCALHOST_URL,
      accounts: [process.env.GANACHE_PRIVATE_KEY],
      chainId: 1337,
      timeout: 1_000_000,
    },
    base: {
      url: process.env.BASE_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 8453,
    },
    base_sepolia: {
      url: process.env.BASE_SEPOLIA_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 84532,
    },
    sepolia: {
      url: process.env.SEPOLIA_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
    },
    optimism_sepolia: {
      url: process.env.OPTIMISM_SEPOLIA_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155420,
    },
    opBNB_testnet: {
      url: process.env.OP_BNB_TESTNET_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 5611,
    },
  },
  loggingEnabled: true,
  solidity: {
    version: '0.8.19',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
      // evmVersion: 'cancun',
    },
  },
  sourcify: {
    enabled: true,
  },
  etherscan: {
    apiKey: {
      baseSepolia: process.env.BASE_API_TOKEN,
      base: process.env.BASE_API_TOKEN,
    }, // command to run: npx hardhat verify --network <contract address>
  },
}
