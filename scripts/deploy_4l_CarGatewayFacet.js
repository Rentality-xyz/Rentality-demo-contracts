const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('CarGatewayFacet')

  if (chainId < 0) throw new Error('chainId is not set')

  const carMainAddress = checkNotNull(
    getContractAddress('CarMain', 'scripts/deploy_3_CarGatewayAdapter.js', chainId),
    'CarMain'
  )
  const carQueryAddress = checkNotNull(
    getContractAddress('CarQuery', 'scripts/deploy_3_CarGatewayAdapter.js', chainId),
    'CarQuery'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const userProfileQueryAddress = checkNotNull(
    getContractAddress('UserProfileQuery', 'scripts/deploy_1i_UserProfileQuery.js', chainId),
    'UserProfileQuery'
  )
  const pricingServiceAddress = checkNotNull(
    getContractAddress('RentalPricingMain', 'scripts/deploy_3j_RentalPricingMain.js', chainId),
    'RentalPricingMain'
  )
  const insuranceServiceAddress = checkNotNull(
    getContractAddress('RentalInsuranceMain', 'scripts/deploy_3l_RentalInsuranceMain.js', chainId),
    'RentalInsuranceMain'
  )
  const referralProgramAddress = checkNotNull(
    getContractAddress('RentalReferralMain', 'scripts/deploy_3n_RentalReferralMain.js', chainId),
    'RentalReferralMain'
  )
  const promoServiceAddress = checkNotNull(
    getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
    'RentalityPromoService'
  )
  const dimoServiceAddress = checkNotNull(
    getContractAddress('RentalityDimoService', 'scripts/deploy_3e_RentalityDimoService.js', chainId),
    'RentalityDimoService'
  )
  const geoServiceAddress = checkNotNull(
    getContractAddress('RentalityGeoService', 'scripts/deploy_2f_RentalityGeoService.js', chainId),
    'RentalityGeoService'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    carMainAddress,
    carQueryAddress,
    tripQueryAddress,
    userProfileMainAddress,
    userProfileQueryAddress,
    pricingServiceAddress,
    insuranceServiceAddress,
    referralProgramAddress,
    promoServiceAddress,
    dimoServiceAddress,
    geoServiceAddress,
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
