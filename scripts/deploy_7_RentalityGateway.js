const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { createFacetCut } = require('./utils/createFacetCut')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGateway')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityNotificationService= checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
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
  await contract.setNotificationService(rentalityNotificationService)

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
