const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress, readFromFile } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('TripMainFacet1')

  if (chainId < 0) throw new Error('chainId is not set')

  const tripMainAddress = checkNotNull(
    getContractAddress('TripMain', 'scripts/deploy_3s_TripMain.js', chainId),
    'TripMain'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const carQueryAddress = checkNotNull(
    getContractAddress('CarQuery', 'scripts/deploy_3_CarModel.js', chainId),
    'CarQuery'
  )
  const carTaxAdapterAddress = checkNotNull(
    getContractAddress('CarTaxAdapter', 'scripts/deploy_3r_CarTaxAdapter.js', chainId),
    'CarTaxAdapter'
  )
  const pricingMainAddress = checkNotNull(
    getContractAddress('PricingMain', 'scripts/deploy_3j_RentalPricingMain.js', chainId),
    'PricingMain'
  )
  const paymentMainAddress = checkNotNull(
    getContractAddress('PaymentMain', 'scripts/deploy_3h_RentalPaymentMain.js', chainId),
    'PaymentMain'
  )
  const currencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_RentalInsuranceMain.js', chainId),
    'InsuranceMain'
  )
  const promoServiceAddress = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const referralMainAddress = checkNotNull(
    getContractAddress('ReferralMain', 'scripts/deploy_3n_RentalReferralMain.js', chainId),
    'ReferralMain'
  )
  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  let tripLibAddress = readFromFile('TripLib', chainId)
  if (!tripLibAddress) {
    const tripLibFactory = await ethers.getContractFactory('TripLib')
    const tripLib = await tripLibFactory.deploy()
    await tripLib.waitForDeployment()
    tripLibAddress = await tripLib.getAddress()
    console.log(`TripLib was deployed to: ${tripLibAddress}`)
    addressSaver(tripLibAddress, 'TripLib', true, chainId)
    await saveJsonAbi('TripLib', chainId, tripLib)
  }

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      TripLib: tripLibAddress,
    },
  })
  const contract = await upgrades.deployProxy(contractFactory, [
    tripMainAddress,
    userProfileMainAddress,
    userProfileMainAddress,
    carQueryAddress,
    carTaxAdapterAddress,
    pricingMainAddress,
    paymentMainAddress,
    currencyConverterAddress,
    insuranceMainAddress,
    promoServiceAddress,
    referralMainAddress,
    notificationServiceAddress,
  ], {
    unsafeAllowLinkedLibraries: true,
  })
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
