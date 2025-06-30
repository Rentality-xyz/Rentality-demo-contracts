const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_2_0.abi.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { chainId, deployer } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
  const patrolEngine = checkNotNull(
    getContractAddress('RentalityPetrolEngine', 'scripts/deploy_2b_1_RentalityPatrolEngine.js', chainId),
    'RentalityPetrolEngine'
  )

  const electricEngine = checkNotNull(
    getContractAddress('RentalityElectricEngine', 'scripts/deploy_2b_2_RentalityElectricEngine.js', chainId),
    'RentalityElectricEngine'
  )

  const engineAddress = checkNotNull(
    getContractAddress('RentalityEnginesService', 'scripts/deploy_2b_RentalityEngineService.js', chainId),
    'RentalityEnginesService'
  )

  const contract = await ethers.getContractAt('RentalityEnginesService', engineAddress)

  console.log(await contract.updateEngineService(patrolEngine, 1))
  console.log(await contract.updateEngineService(electricEngine, 2))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
