const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { createFacetCut } = require('./utils/createFacetCut')

async function main() {
  const deploymentName = 'RentalityGateway'
  const implementationName = 'AppGateway'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityNotificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
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
  const carViewGatewayFacet1Address = checkNotNull(
    getContractAddress('CarViewGatewayFacet1', 'scripts/deploy_4m1_CarViewGatewayFacet1.js', chainId),
    'CarViewGatewayFacet1'
  )
  const paymentGatewayFacetAddress = checkNotNull(
    getContractAddress('PaymentGatewayFacet', 'scripts/deploy_4n_PaymentGatewayFacet.js', chainId),
    'PaymentGatewayFacet'
  )
  const pricingGatewayFacetAddress = checkNotNull(
    getContractAddress('PricingGatewayFacet', 'scripts/deploy_4o_PricingGatewayFacet.js', chainId),
    'PricingGatewayFacet'
  )
  const insuranceGatewayFacetAddress = checkNotNull(
    getContractAddress('InsuranceGatewayFacet', 'scripts/deploy_4p_InsuranceGatewayFacet.js', chainId),
    'InsuranceGatewayFacet'
  )

  const contractFactory = await ethers.getContractFactory(implementationName, {
    libraries: {},
  })

  let contract = await upgrades.deployProxy(contractFactory, [[]])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  const profileFacet = await ethers.getContractAt('IProfileGatewayFacet', profileGatewayFacetAddress)
  const tripFacet = await ethers.getContractAt('ITripGatewayFacet', tripGatewayFacetAddress)
  const carFacet = await ethers.getContractAt('ICarGatewayFacet', carGatewayFacetAddress)
  const carViewFacet = await ethers.getContractAt('ICarViewGatewayFacet', carViewGatewayFacetAddress)
  const carViewFacet1 = await ethers.getContractAt('ICarViewGatewayFacet1', carViewGatewayFacet1Address)
  const paymentFacet = await ethers.getContractAt('IPaymentGatewayFacet', paymentGatewayFacetAddress)
  const pricingFacet = await ethers.getContractAt('IPricingGatewayFacet', pricingGatewayFacetAddress)
  const insuranceFacet = await ethers.getContractAt('IInsuranceGatewayFacet', insuranceGatewayFacetAddress)
  const investmentFacet = await ethers.getContractAt('IInvestmentGatewayFacet', investmentGatewayFacetAddress)
  const referralFacet = await ethers.getContractAt('IReferralGatewayFacet', referralGatewayFacetAddress)

  const facetCuts = [
    createFacetCut(profileFacet),
    createFacetCut(tripFacet),
    createFacetCut(carFacet),
    createFacetCut(carViewFacet),
    createFacetCut(carViewFacet1),
    createFacetCut(paymentFacet),
    createFacetCut(pricingFacet),
    createFacetCut(insuranceFacet),
    createFacetCut(investmentFacet),
    createFacetCut(referralFacet),
  ]

  await contract.diamondCut(facetCuts, { gasLimit: 5000000 })
  await contract.setNotificationService(rentalityNotificationService)

  contract = await ethers.getContractAt('IGatewaySurface', contractAddress)

  console.log(`${implementationName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, deploymentName, true, chainId)
  addressSaver(contractAddress, implementationName, true, chainId)
  await saveJsonAbi(deploymentName, chainId, contract)
  await saveJsonAbi(implementationName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
