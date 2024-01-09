const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')
const getContractAddress = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')

async function main() {
  const contractName = 'RentalityAdminGateway'
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer)

  console.log('Deployer address is:', await deployer.getAddress(), ' with balance:', balance)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  const rentalityPaymentServiceAddress = getContractAddress(
    'RentalityPaymentService',
    'scripts/deploy_2d_RentalityPaymentService.js'
  )

  const rentalityUserServiceAddress = getContractAddress(
    'RentalityUserService',
    'scripts/deploy_1b_RentalityUserService.js'
  )

  const rentalityPlatformAddress = getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js')

  console.log('rentalityPaymentServiceAddress is:', rentalityPaymentServiceAddress)

  console.log('rentalityUserServiceAddress is:', rentalityUserServiceAddress)
  console.log('rentalityPlatformAddress is:', rentalityPlatformAddress)

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityUserServiceAddress,
    rentalityPlatformAddress,
    rentalityPaymentServiceAddress,
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
