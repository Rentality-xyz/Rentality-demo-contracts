const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityAdminGateway')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js', chainId),
    'RentalityUtils'
  )
  const rentalityViewLib = checkNotNull(
    getContractAddress('RentalityViewLib', 'scripts/deploy_1g_RentalityViewLib.js', chainId),
    'RentalityViewLib'
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
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
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
    getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
    'RentalityView'
  )
  const rentalityTripsQueryAddress = checkNotNull(
    getContractAddress('RentalityTripsQuery', 'scripts/deploy_1e_RentalityTripsQuery.js', chainId),
    'RentalityTripsQuery'
  )
  const rentalityQueryAddress = checkNotNull(
    getContractAddress('RentalityQuery', 'scripts/deploy_1d_RentalityQuery.js', chainId),
    'RentalityQuery'
  )
  const rentalityInsurance = checkNotNull(
    getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
    'RentalityInsurance'
  )

  const rentalityRefferalProgram = checkNotNull(
    getContractAddress('RentalityReferralProgram', 'scripts/deploy_3e_RentalityReferralProgram.js', chainId),
    'RentalityReferralProgram'
  )
  const rentalityTripsView = checkNotNull(
    getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
    'RentalityTripsView'
  )
  const rentalityPromoService = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const dimoService = checkNotNull(
    getContractAddress('RentalityDimoService', 'scripts/deploy_3e_RentalityDimoService.js', chainId),
    'RentalityDimoService'
  )
  const investService = checkNotNull(
    getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
    'RentalityInvestment'
  )


  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityViewLib: rentalityViewLib,
      RentalityUtils: rentalityUtilsAddress,
    },
  })

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
    rentalityInsurance,
    rentalityTripsView,
    rentalityRefferalProgram,
    rentalityPromoService,
    dimoService,
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
