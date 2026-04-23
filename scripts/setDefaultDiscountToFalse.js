const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { chainId } = await startDeploy('')
  const pricingMain = checkNotNull(
    getContractAddress('PricingMain', 'scripts/deploy_3j_PricingMain.js', chainId),
    'PricingMain'
  )

  const contract = await ethers.getContractAt('PricingMain', pricingMain)

  console.log(await contract.setDefaultDiscountToFalse())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
