const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const {
  emptyLocationInfo,
  getEmptySearchCarParams,
  taxesWithGovePMM,
  taxesWithoutRentSign,
  taxesWithRentSign,
  encodeTaxes,
  taxesGOVConst,
  TaxesLocationType,
} = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalitGateway = checkNotNull(
    getContractAddress('RentalityGateway', 'deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )

  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )
  const rentalitGatewayContract = await ethers.getContractAt('RentalityGateway', rentalitGateway)

  console.log(await rentalitGatewayContract.setNotificationService(notificationService))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
