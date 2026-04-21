const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityAdminGateway = checkNotNull(
    getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
    'RentalityAdminGateway'
  )

  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const adminGateway = await ethers.getContractAt('RentalityAdminGateway', rentalityAdminGateway)

  console.log(await adminGateway.updateNotificationService(notificationService))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
