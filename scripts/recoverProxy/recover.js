const { ethers, upgrades } = require('hardhat')
const { startRecovering } = require('./common')
const { readFromFile, getContractAddress } = require('../utils/contractAddress')
const { checkNotNull } = require('../utils/deployHelper')
const getContractLibs = require('../utils/libSearch')
const upgradesCore = require('@openzeppelin/upgrades-core');

async function main() {
  let [contractName, chainId] = await startRecovering()

  const contractAddress = checkNotNull(readFromFile(contractName, chainId), contractName)

  const libs = getContractLibs(contractName, chainId)

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: libs,
  })
  const _ = await upgrades.forceImport(contractAddress, contractFactory)
  console.log('Proxy files successfully recovered!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
