// /** @type import('hardhat/config').HardhatUserConfig */
// require('@nomiclabs/hardhat-waffle')

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
      url: process.env.URL_LOCALHOST_GANACHE,
      accounts: [process.env.GANACHE_PRIVATE_KEY],
      chainId: 1337,
      timeout: 1_000_000,
    },
    goerli: {
      url: process.env.ALCHEMY_API_URL_GOERLI ?? '',
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: process.env.ALCHEMY_API_URL_MUMBAI ?? '',
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: process.env.ALCHEMY_API_URL_SEPOLIA ?? '',
      accounts: [process.env.PRIVATE_KEY],
    },
    optimism_sepolia: {
      url: process.env.OPTIMISM_SEPOLIA_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155420,
    },
    base_sepolia: {
      url: process.env.BASE_SEPOLIA_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 84532,
    },
    opBNB: {
      url: process.env.OP_BNB_URL ?? '',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 5611,
    },
  },
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
}
