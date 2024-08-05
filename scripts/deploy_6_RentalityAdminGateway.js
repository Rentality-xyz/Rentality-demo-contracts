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

  const rentalityClaimService = checkNotNull(
    getContractAddress('RentalityClaimService', 'scripts/deploy_2a_RentalityClaimService.js', chainId),
    'RentalityClaimService'
  )

  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )

  const rentalityPaymentServiceAddress = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3d_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )

  const rentalityCarTokenAddress = checkNotNull(
    getContractAddress('RentalityCarToken', 'scripts/deploy_3_RentalityCarToken.js', chainId),
    'RentalityCarToken'
  )

  const rentalityTripServiceAddress = checkNotNull(
    getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
    'RentalityTripService'
  )

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
    'RentalityPlatform'
  )
  const rentalityCarDelivery = checkNotNull(
    getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
    'RentalityCarDelivery'
  )
  const rentalityView = checkNotNull(
    getContractAddress('RentalityView', 'scripts/deploy_4b_RentalityView.js', chainId),
    'RentalityView'
  )

  const investService = checkNotNull(
      getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
      'RentalityInvestment'
  )
  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress,
    rentalityPlatformAddress,
    rentalityPaymentServiceAddress,
    rentalityClaimService,
    rentalityCarDelivery,
    rentalityView,
    investService
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
