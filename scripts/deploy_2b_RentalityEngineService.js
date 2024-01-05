const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const addressSaver = require('./utils/addressSaver')
const getContractAddress = require('./utils/contractAddress')

async function main() {
  const chainId = network.config.chainId

  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer)
  console.log('Deployer address is:', await deployer.getAddress(), ' with balance:', balance)

  const userService = getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js')

  const patrolName = 'RentalityPatrolEngine'
  const patrolEngine = await ethers.getContractFactory(patrolName)
  const pEngine = await patrolEngine.deploy(userService)
  await pEngine.waitForDeployment()

  addressSaver(await pEngine.getAddress(), patrolName, true)
  await saveJsonAbi(patrolName, chainId, pEngine)

  const electricName = 'RentalityElectricEngine'
  const electricEngine = await ethers.getContractFactory(electricName)
  const elEngine = await electricEngine.deploy(userService)

  await elEngine.waitForDeployment()

  addressSaver(await elEngine.getAddress(), electricName, true)
  await saveJsonAbi(electricName, chainId, elEngine)

  const hybridName = 'RentalityHybridEngine'
  const hybridEngine = await ethers.getContractFactory(hybridName)
  const hEngine = await hybridEngine.deploy(userService)

  await hEngine.waitForDeployment()

  addressSaver(await hEngine.getAddress(), hybridName, true)
  await saveJsonAbi(hybridName, chainId, hEngine)

  const contractName = 'RentalityEnginesService'
  const EngineService = await ethers.getContractFactory(contractName)

  if (network.name === 'hardhat') {
    console.log('WARNING: might have admin role issue in hardhat network')
  }
  const contract = await upgrades.deployProxy(EngineService, [
    userService,
    [await pEngine.getAddress(), await elEngine.getAddress(), await hEngine.getAddress()],
  ])
  await contract.waitForDeployment()

  console.log(contractName + ' deployed to:', await contract.getAddress())

  addressSaver(await contract.getAddress(), contractName, true)
  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
