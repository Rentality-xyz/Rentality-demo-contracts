const { ethers, upgrades } = require('hardhat')
const { startRecovering } = require('./common')
const { readFromFile, getContractAddress } = require('../utils/contractAddress')
const { checkNotNull } = require('../utils/deployHelper')

async function main() {
  let [contractName, chainId] = await startRecovering()

  contractName = checkNotNull(readFromFile(contractName, chainId), contractName)

  const contractFactory = await ethers.getContractFactory(contractName)

  const _ = await upgrades.forceImport(contractName, contractFactory)

  console.log('Proxy files successfully recovered!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
