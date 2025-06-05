const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams, taxesWithGovePMM, taxesWithoutRentSign, taxesWithRentSign, encodeTaxes, taxesGOVConst, TaxesLocationType } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
 
    const rentalityPlatformHelper = checkNotNull(
        getContractAddress('RentalityPlatformHelper', 'scripts/deploy_4g_RentalityPlatformHelper.js', chainId),
        'RentalityPlatformHelper'
      )

      const rentalityAdminGateway = checkNotNull(
        getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
        'RentalityAdminGateway'
      )
      
      const notificationService = checkNotNull(
        getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
        'RentalityNotificationService'
      )

      const adminGateway = await ethers.getContractAt("RentalityAdminGateway",rentalityAdminGateway)
      const platformHelper = await ethers.getContractAt("RentalityPlatformHelper", rentalityPlatformHelper)

        console.log(await platformHelper.setNotificationService(notificationService))
        console.log(await adminGateway.setNotificationService(notificationService))

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
