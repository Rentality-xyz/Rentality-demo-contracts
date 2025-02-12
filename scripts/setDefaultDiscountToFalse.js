const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
    const { chainId } = await startDeploy('')
    const baseDiscount = checkNotNull(
        getContractAddress('RentalityBaseDiscount', 'scripts/deploy_2g_RentalityBaseDiscount.js', chainId),
        'RentalityBaseDiscount'
      )

      const contract = await ethers.getContractAt('RentalityBaseDiscount',baseDiscount)

      console.log(await contract.setDefaultDiscountToFalse())
}

  main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })