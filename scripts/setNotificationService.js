const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityGateway = checkNotNull(
    getContractAddress('RentalityGateway', 'scripts/deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )

  const notificationService = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const gateway = await ethers.getContractAt('AppGateway', rentalityGateway)

  console.log(await gateway.setNotificationService(notificationService))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
