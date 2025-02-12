const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityTripsView')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js', chainId),
    'RentalityUtils'
  )
  const rentalityQueryAddress = checkNotNull(
    getContractAddress('RentalityQuery', 'scripts/deploy_1d_RentalityQuery.js', chainId),
    'RentalityQuery'
  )
  const rentalityTripsQueryAddress = checkNotNull(
    getContractAddress('RentalityTripsQuery', 'scripts/deploy_1e_RentalityTripsQuery.js', chainId),
    'RentalityTripsQuery'
  )

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

  const rentalityCarDelivery = checkNotNull(
    getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
    'RentalityCarDelivery'
  )
  const rentalityInsurance = checkNotNull(
    getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
    'RentalityInsurance'
  )

  const rentalityPromoService = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const dimoService = checkNotNull(
    getContractAddress('RentalityDimoService', 'scripts/deploy_3e_RentalityDimoService.js', chainId),
    'RentalityDimoService'
  )
  const rentalityViewLib = checkNotNull(
    getContractAddress('RentalityViewLib', 'scripts/deploy_1g_RentalityViewLib.js', chainId),
    'RentalityViewLib'
  )
  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityTripsQuery: rentalityTripsQueryAddress,
      rentalityViewLib: rentalityViewLib
    },
  })
  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress,
    rentalityPaymentServiceAddress,
    rentalityClaimService,
    rentalityCarDelivery,
    rentalityInsurance,
    rentalityPromoService,
    dimoService
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
