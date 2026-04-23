const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('AdminGatewayFacet')

  if (chainId < 0) throw new Error('chainId is not set')

  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const paymentMainAddress = checkNotNull(
    getContractAddress('PaymentMain', 'scripts/deploy_3h_PaymentMain.js', chainId),
    'PaymentMain'
  )
  const pricingMainAddress = checkNotNull(
    getContractAddress('PricingMain', 'scripts/deploy_3j_PricingMain.js', chainId),
    'PricingMain'
  )
  const carMainAddress = checkNotNull(
    getContractAddress('CarMain', 'scripts/deploy_3_CarModel.js', chainId),
    'CarMain'
  )
  const carQueryFacet2Address = checkNotNull(
    getContractAddress('CarQueryFacet2', 'scripts/deploy_3w_CarQueryFacet2.js', chainId),
    'CarQueryFacet2'
  )
  const userProfileQueryAddress = checkNotNull(
    getContractAddress('UserProfileQuery', 'scripts/deploy_1i_UserProfileQuery.js', chainId),
    'UserProfileQuery'
  )
  const geoServiceAddress = checkNotNull(
    getContractAddress('RentalityGeoService', 'scripts/deploy_2f_RentalityGeoService.js', chainId),
    'RentalityGeoService'
  )
  const carDeliveryAddress = checkNotNull(
    getContractAddress('CarMain', 'scripts/deploy_3_CarModel.js', chainId),
    'CarMain'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
  )
  const referralMainAddress = checkNotNull(
    getContractAddress('ReferralMain', 'scripts/deploy_3n_ReferralMain.js', chainId),
    'ReferralMain'
  )
  const referralMainFacet1Address = checkNotNull(
    getContractAddress('ReferralMainFacet1', 'scripts/deploy_3n1_ReferralMainFacet1.js', chainId),
    'ReferralMainFacet1'
  )
  const promoServiceAddress = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const dimoService = checkNotNull(
    getContractAddress('RentalityDimoService', 'scripts/deploy_3e_RentalityDimoService.js', chainId),
    'RentalityDimoService'
  )
  const investService = checkNotNull(
    getContractAddress('InvestmentMain', 'scripts/deploy_3p_InvestmentMain.js', chainId),
    'InvestmentMain'
  )
  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )
  const tripGatewayFacetAddress = checkNotNull(
    getContractAddress('TripGatewayFacet', 'scripts/deploy_4k_TripGatewayFacet.js', chainId),
    'TripGatewayFacet'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )

  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [
    [
      carMainAddress,
      rentalityCurrencyConverterAddress,
      userProfileMainAddress,
      paymentMainAddress,
      pricingMainAddress,
      referralMainFacet1Address,
      carDeliveryAddress,
      ethers.ZeroAddress,
    ],
    [
      insuranceMainAddress,
      referralMainAddress,
      promoServiceAddress,
      dimoService,
      investService,
      notificationService,
    ],
    [tripGatewayFacetAddress, tripQueryAddress, carQueryFacet2Address, userProfileQueryAddress, geoServiceAddress],
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
