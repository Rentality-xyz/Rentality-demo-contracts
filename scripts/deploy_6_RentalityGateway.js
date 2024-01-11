const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGateway')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js'),
    'RentalityUtils'
  )

  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js'),
    'RentalityUserService'
  )

  const rentalityClaimService = checkNotNull(
    getContractAddress('RentalityClaimService', 'scripts/deploy_2a_RentalityClaimService.js'),
    'RentalityClaimService'
  )

  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_2c_RentalityCurrencyConverter.js'),
    'RentalityCurrencyConverter'
  )

  const rentalityPaymentServiceAddress = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_2d_RentalityPaymentService.js'),
    'RentalityPaymentService'
  )

  const rentalityCarTokenAddress = checkNotNull(
    getContractAddress('RentalityCarToken', 'scripts/deploy_3_RentalityCarToken.js'),
    'RentalityCarToken'
  )

  const rentalityTripServiceAddress = checkNotNull(
    getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js'),
    'RentalityTripService'
  )

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js'),
    'RentalityPlatform'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: { RentalityUtils: rentalityUtilsAddress },
  })

  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress,
    rentalityPlatformAddress,
    rentalityPaymentServiceAddress,
    rentalityClaimService,
  ])
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
