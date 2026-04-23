const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('ReferralMainFacet1')

  if (chainId < 0) throw new Error('chainId is not set')

  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const paymentMainAddress = checkNotNull(
    getContractAddress('PaymentMain', 'scripts/deploy_3h_PaymentMain.js', chainId),
    'PaymentMain'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    userProfileMainAddress,
    notificationServiceAddress,
    tripQueryAddress,
    rentalityCurrencyConverterAddress,
    paymentMainAddress,
    insuranceMainAddress,
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
