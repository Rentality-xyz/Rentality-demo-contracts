const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('TripGatewayFacet')

  if (chainId < 0) throw new Error('chainId is not set')

  const tripMainAddress = checkNotNull(
    getContractAddress('TripMain', 'scripts/deploy_3s_TripMain.js', chainId),
    'TripMain'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const carQueryAddress = checkNotNull(
    getContractAddress('CarQuery', 'scripts/deploy_3_CarGatewayAdapter.js', chainId),
    'CarQuery'
  )
  const carTaxAdapterAddress = checkNotNull(
    getContractAddress('CarTaxAdapter', 'scripts/deploy_3r_CarTaxAdapter.js', chainId),
    'CarTaxAdapter'
  )
  const pricingServiceAddress = checkNotNull(
    getContractAddress('RentalPricingMain', 'scripts/deploy_3j_RentalPricingMain.js', chainId),
    'RentalPricingMain'
  )
  const paymentServiceAddress = checkNotNull(
    getContractAddress('RentalPaymentMain', 'scripts/deploy_3h_RentalPaymentMain.js', chainId),
    'RentalPaymentMain'
  )
  const currencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const insuranceServiceAddress = checkNotNull(
    getContractAddress('RentalInsuranceMain', 'scripts/deploy_3l_RentalInsuranceMain.js', chainId),
    'RentalInsuranceMain'
  )
  const promoServiceAddress = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const referralProgramAddress = checkNotNull(
    getContractAddress('RentalReferralMain', 'scripts/deploy_3n_RentalReferralMain.js', chainId),
    'RentalReferralMain'
  )
  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )


  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    tripMainAddress,
    tripQueryAddress,
    userProfileMainAddress,
    carQueryAddress,
    carTaxAdapterAddress,
    pricingServiceAddress,
    paymentServiceAddress,
    currencyConverterAddress,
    insuranceServiceAddress,
    promoServiceAddress,
    referralProgramAddress,
    notificationServiceAddress,
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




