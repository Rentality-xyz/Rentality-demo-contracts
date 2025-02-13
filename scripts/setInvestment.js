const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams, zeroHash } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
  const userService = checkNotNull(
        getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
        'RentalityUserService'
      )
      const paymentService = checkNotNull(
        getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
        'RentalityPaymentService'
      )

      const adminGateway = checkNotNull(
        getContractAddress('RentalityAdminGateway','scripts/deploy_6_RentalityAdminGateway.js',chainId),
        'RentalityAdminGateway'
      )

      const investService = checkNotNull(
        getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
        'RentalityInvestment'
      )
    const paymentContract = await ethers.getContractAt('RentalityPaymentService', paymentService)
        await paymentContract.setInvestmentService(investService)
    const adminService = await ethers.getContractAt('RentalityAdminGateway',adminGateway)
        await adminService.updateInvestmentAddress(investService)
    const userContract = await ethers.getContractAt('RentalityUserService', userService)
        await userContract.grantManagerRole(grantManagerRole)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
 