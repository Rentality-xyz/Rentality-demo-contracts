const { ethers } = require('hardhat')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')
async function main() {
  console.log('Adding notification service...')

  const [deployer] = await ethers.getSigners()

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1

  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
    return
  }

  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityUserServRentalityNotificationServiceice'
  )
  const rentalityUserServiceAddress = checkNotNull(addresses['RentalityUserService'], 'rentalityUserServiceAddress')
  const rentalityClaimService = checkNotNull(addresses['RentalityClaimService'], 'RentalityClaimService')
  const rentalityTripServiceAddress = checkNotNull(addresses['RentalityTripService'], 'rentalityTripServiceAddress')
  const rentalityCarTokenAddress = checkNotNull(addresses['RentalityCarToken'], 'rentalityCarTokenAddress')

  const userService = await ethers.getContractAt('RentalityUserService', rentalityUserServiceAddress)
  const claimService = await ethers.getContractAt('RentalityClaimService', rentalityClaimService)
  const carService = await ethers.getContractAt('RentalityCarToken', rentalityCarTokenAddress)
  const tripService = await ethers.getContractAt('RentalityTripService', rentalityTripServiceAddress)

  await claimService.updateEventServiceAddress(notificationService)
  await carService.updateEventServiceAddress(notificationService)
  await tripService.updateEventServiceAddress(notificationService)
  await userService.grantManagerRole(claimService)

  console.log('Event service added!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
