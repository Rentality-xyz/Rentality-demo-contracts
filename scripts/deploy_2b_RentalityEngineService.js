const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const addressSaver = require('./utils/addressSaver')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityEnginesService')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js'),
    'RentalityUserService'
  )

  const patrolEngine = checkNotNull(
    getContractAddress('RentalityPatrolEngine', 'scripts/deploy_2b_1_RentalityPatrolEngine.js'),
    'RentalityPatrolEngine'
  )

  const electricEngine = checkNotNull(
    getContractAddress('RentalityElectricEngine', 'scripts/deploy_2b_2_RentalityElectricEngine.js'),
    'RentalityElectricEngine'
  )

  if (network.name === 'hardhat') {
    console.warn('WARNING: might have admin role issue in hardhat network')
  }

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [userService, [patrolEngine, electricEngine]])
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
