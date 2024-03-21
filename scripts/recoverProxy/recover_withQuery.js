const { ethers, upgrades } = require('hardhat')
const { startRecovering } = require('./common')
const { readFromFile, getContractAddress } = require('../utils/contractAddress')
const { checkNotNull } = require('../utils/deployHelper')

async function main() {
  let [contractName, chainId] = await startRecovering()

  const rentalityQueryAddress = checkNotNull(
    getContractAddress('RentalityQuery', 'scripts/deploy_1d_RentalityQuery.js', chainId),
    'RentalityQuery'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityQuery: rentalityQueryAddress,
    },
  })

  const proxyAddress = checkNotNull(readFromFile(contractName, chainId), contractName)

  const _ = await upgrades.forceImport(proxyAddress, contractFactory)

  console.log('Proxy files successfully recovered!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
