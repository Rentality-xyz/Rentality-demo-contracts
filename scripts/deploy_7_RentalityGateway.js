const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { createFacetCut } = require('./utils/createFacetCut')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGateway')

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

  const rentalityAdminGatewayAddress = checkNotNull(
    getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
    'RentalityAdminGateway'
  )

  const rentalityCarDelivery = checkNotNull(
    getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
    'RentalityCarDelivery'
  )
  const rentalityView = checkNotNull(
    getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
    'RentalityView'
  )
  const rentalityPlatformHelper = checkNotNull(
    getContractAddress('RentalityPlatformHelper', 'scripts/deploy_4g_RentalityPlatformHelper.js', chainId),
    'RentalityPlatformHelper'
  )
  const rentalityTripsView = checkNotNull(
    getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
    'RentalityTripsView'
  )
  const rentalityInvestment = checkNotNull(
    getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
    'RentalityInvestment'
  )
  const rentalityReferralProgram = checkNotNull(
    getContractAddress('RentalityReferralProgram', 'scripts/deploy_3e_RentalityReferralProgram.js', chainId),
    'RentalityReferralProgram'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {},
  })

  // Deploy empty and wire facets via diamond cut
  let contract = await upgrades.deployProxy(contractFactory, [[]])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  // Build facet cuts
  const viewFacet = await ethers.getContractAt('IRentalityViewFacet', rentalityView)
  const platformFacet = await ethers.getContractAt('IRentalityPlatformFacet', rentalityPlatformAddress)
  const platformHelperFacet = await ethers.getContractAt('IRentalityPlatformHelperFacet', rentalityPlatformHelper)
  const tripsViewFacet = await ethers.getContractAt('IRentalityTripsViewFacet', rentalityTripsView)
  const investmentFacet = await ethers.getContractAt('IRentalityInvestmentFacet', rentalityInvestment)
  const referralFacet = await ethers.getContractAt('IRentalityReferralProgramFacet', rentalityReferralProgram)

  const facetCuts = [
    createFacetCut(viewFacet),
    createFacetCut(platformFacet),
    createFacetCut(platformHelperFacet),
    createFacetCut(tripsViewFacet),
    createFacetCut(investmentFacet),
    createFacetCut(referralFacet),
  ]

  await contract.diamondCut(facetCuts,{gasLimit: 5000000})

  contract = await ethers.getContractAt('IRentalityGateway', contractAddress)

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
