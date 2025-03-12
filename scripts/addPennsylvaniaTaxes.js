const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams, zeroHash } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const paymentService = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )

  const taxesContract = checkNotNull(
    getContractAddress('RentalityPennsylvaniaTaxes', 'scripts/deploy_2m_RentalityPenncsylvaniaTaxes.js', chainId),
    'RentalityPennsylvaniaTaxes'
  )

    const contract = await ethers.getContractAt('RentalityPaymentService',paymentService)
    console.log(await contract.addTaxesContract(taxesContract))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })