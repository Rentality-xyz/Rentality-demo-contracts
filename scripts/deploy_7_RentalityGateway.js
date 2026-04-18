const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { createFacetCut, FacetCutAction } = require('./utils/createFacetCut')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGateway')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityNotificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
    'RentalityPlatform'
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
  const profileGatewayFacetAddress = checkNotNull(
    getContractAddress('ProfileGatewayFacet', 'scripts/deploy_4h_ProfileGatewayFacet.js', chainId),
    'ProfileGatewayFacet'
  )
  const referralGatewayFacetAddress = checkNotNull(
    getContractAddress('ReferralGatewayFacet', 'scripts/deploy_4i_ReferralGatewayFacet.js', chainId),
    'ReferralGatewayFacet'
  )
  const investmentGatewayFacetAddress = checkNotNull(
    getContractAddress('InvestmentGatewayFacet', 'scripts/deploy_4j_InvestmentGatewayFacet.js', chainId),
    'InvestmentGatewayFacet'
  )
  const tripGatewayFacetAddress = checkNotNull(
    getContractAddress('TripGatewayFacet', 'scripts/deploy_4k_TripGatewayFacet.js', chainId),
    'TripGatewayFacet'
  )
  const carGatewayFacetAddress = checkNotNull(
    getContractAddress('CarGatewayFacet', 'scripts/deploy_4l_CarGatewayFacet.js', chainId),
    'CarGatewayFacet'
  )
  const carViewGatewayFacetAddress = checkNotNull(
    getContractAddress('CarViewGatewayFacet', 'scripts/deploy_4m_CarViewGatewayFacet.js', chainId),
    'CarViewGatewayFacet'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {},
  })

  let contract = await upgrades.deployProxy(contractFactory, [[]])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  const viewFacet = await ethers.getContractAt('IRentalityViewCoreFacet', rentalityView)
  const profileFacet = await ethers.getContractAt('IProfileGatewayFacet', profileGatewayFacetAddress)
  const platformFacet = await ethers.getContractAt('IRentalityPlatformFacet', rentalityPlatformAddress)
  const platformHelperFacet = await ethers.getContractAt('IRentalityPlatformHelperCoreFacet', rentalityPlatformHelper)
  const tripsViewFacet = await ethers.getContractAt('IRentalityTripsViewFacet', rentalityTripsView)
  const tripFacet = await ethers.getContractAt('ITripGatewayFacet', tripGatewayFacetAddress)
  const carFacet = await ethers.getContractAt('ICarGatewayFacet', carGatewayFacetAddress)
  const carViewFacet = await ethers.getContractAt('ICarViewGatewayFacet', carViewGatewayFacetAddress)
  const investmentFacet = await ethers.getContractAt('IInvestmentGatewayFacet', investmentGatewayFacetAddress)
  const referralFacet = await ethers.getContractAt('IReferralGatewayFacet', referralGatewayFacetAddress)

  const facetCuts = [
    createFacetCut(viewFacet),
    createFacetCut(profileFacet),
    createFacetCut(platformFacet),
    createFacetCut(platformHelperFacet),
    createFacetCut(tripsViewFacet),
    createFacetCut(tripFacet, { action: FacetCutAction.Replace }),
    createFacetCut(carFacet, { action: FacetCutAction.Replace }),
    createFacetCut(carViewFacet, { action: FacetCutAction.Replace }),
    createFacetCut(investmentFacet),
    createFacetCut(referralFacet),
  ]

  await contract.diamondCut(facetCuts, { gasLimit: 5000000 })
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
