const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
    const rentalityPaymentServiceAddress = checkNotNull(
        getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
        'RentalityPaymentService'
      )

      const rentalitySwaps = checkNotNull(
        getContractAddress('RentalitySwaps', 'scripts/deploy_2h_RentalitySwaps.js', chainId),
        'RentalitySwaps'
      )
    
      
      
      let paymentsService = await ethers.getContractAt('RentalityPaymentService', rentalityPaymentServiceAddress)

      console.log(await paymentsService.setSwapContracts(rentalitySwaps))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
