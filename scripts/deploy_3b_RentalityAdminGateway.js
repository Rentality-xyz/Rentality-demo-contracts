const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityAdminGateway')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )

  const rentalityPaymentServiceAddress = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_2d_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
    'RentalityPlatform'
  )

  const rentalityAutomationAddress = checkNotNull(
    getContractAddress('RentalityAutomation', 'scripts/deploy_2e_RentalityAutomation.js', chainId),
    'RentalityAutomation'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityUserServiceAddress,
    rentalityPlatformAddress,
    rentalityPaymentServiceAddress,
    rentalityAutomationAddress,
  ])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
