const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityCarToken')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js'),
    'RentalityUtils'
  )

  const geoAddress = checkNotNull(
    getContractAddress('RentalityGeoService', 'scripts/deploy_1c_GeoService.js'),
    'RentalityGeoService'
  )

  const engineAddress = checkNotNull(
    getContractAddress('RentalityEnginesService', 'scripts/deploy_2b_RentalityEngineService.js'),
    'RentalityEnginesService'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: { RentalityUtils: rentalityUtilsAddress },
  })
  const contract = await upgrades.deployProxy(contractFactory, [geoAddress, engineAddress])
  await contract.waitForDeployment()

  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
