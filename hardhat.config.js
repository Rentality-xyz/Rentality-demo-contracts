/** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-ethers')
require('dotenv').config()
require('@nomicfoundation/hardhat-verify')

module.exports = {
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
    },
    goerli: {
      url: process.env.ALCHEMY_API_URL_GOERLI,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: process.env.ALCHEMY_API_URL_MUMBAI,
      accounts: [process.env.PRIVATE_KEY],
    },
    sepolia: {
      url: process.env.ALCHEMY_API_URL_SEPOLIA,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
}
