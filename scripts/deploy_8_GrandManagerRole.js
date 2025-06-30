const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_2_0.abi.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { chainId, deployer } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
    return
  }

  const rentalityUserServiceAddress = checkNotNull(addresses['RentalityUserService'], 'rentalityUserServiceAddress')
  const rentalityGatewayAddress = checkNotNull(addresses['RentalityGateway'], 'rentalityGatewayAddress')
  const rentalityTripServiceAddress = checkNotNull(addresses['RentalityTripService'], 'rentalityTripServiceAddress')
  const rentalityPlatformAddress = checkNotNull(addresses['RentalityPlatform'], 'rentalityPlatformAddress')
  const rentalityCarTokenAddress = checkNotNull(addresses['RentalityCarToken'], 'rentalityCarTokenAddress')
  const rentalityEngineAddress = checkNotNull(addresses['RentalityEnginesService'], 'rentalityEngineAddress')
  const rentalityAdminGatewayAddress = checkNotNull(addresses['RentalityAdminGateway'], 'rentalityAdminGatewayAddress')
  const rentalityPaymentServiceAddress = checkNotNull(
    addresses['RentalityPaymentService'],
    'rentalityPaymentServiceAddress'
  )
  const rentalityView = checkNotNull(addresses['RentalityView'], 'RentalityViewAddress')
  const rentalityTripsView = checkNotNull(addresses['RentalityTripsView'], 'RentalityTripsViewAddress')
  const rentalityCarDelivery = checkNotNull(addresses['RentalityCarDelivery'], 'RentalityCarDelivery')
  const rentalityClaimService = checkNotNull(addresses['RentalityClaimService'], 'RentalityClaimService')
  const refferalProgram = checkNotNull(addresses['RentalityReferralProgram'], 'RentalityReferralProgram')
  const rentalityPlatformHelper = checkNotNull(addresses['RentalityPlatformHelper'], 'RentalityPlatformHelper')
  const rentalityReferralProgram = checkNotNull(addresses['RentalityReferralProgram'], 'RentalityReferralProgram')
  const rentalityInvestment = checkNotNull(addresses['RentalityInvestment'], 'RentalityInvestment')

  let rentalityUserServiceContract = await ethers.getContractAt('RentalityUserService', rentalityUserServiceAddress)

  await rentalityUserServiceContract.grantPlatformRole(deployer.address)
  await rentalityUserServiceContract.grantPlatformRole(rentalityView)
  await rentalityUserServiceContract.grantPlatformRole(rentalityGatewayAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityTripServiceAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityPlatformAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityCarTokenAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityAdminGatewayAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityEngineAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityPaymentServiceAddress)
  await rentalityUserServiceContract.grantPlatformRole(rentalityCarDelivery)
  await rentalityUserServiceContract.grantPlatformRole(rentalityTripsView)
  await rentalityUserServiceContract.grantPlatformRole(rentalityClaimService)
  await rentalityUserServiceContract.grantPlatformRole(refferalProgram)
  await rentalityUserServiceContract.grantPlatformRole(rentalityPlatformHelper)
  await rentalityUserServiceContract.grantPlatformRole(rentalityReferralProgram)
  await rentalityUserServiceContract.grantPlatformRole(rentalityInvestment)
  console.log('manager role was granded')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('deploy_8_GrandManagerRole error:', error)
    process.exit(1)
  })
