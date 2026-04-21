const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const paymentsAddress = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )

  const payments = await ethers.getContractAt('RentalityPaymentService', paymentsAddress)

  const rentalityHostInsurace = checkNotNull(
    getContractAddress('RentalityHostInsurance', 'scripts/deploy_3g_RentalityHostInsurance.js', chainId),
    'RentalityHostInsurance'
  )

  console.log(await payments.setHostInsuranceService(rentalityHostInsurace))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })



