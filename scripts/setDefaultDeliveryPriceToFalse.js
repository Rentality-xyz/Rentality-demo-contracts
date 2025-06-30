const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { chainId } = await startDeploy('')
  const delivery = checkNotNull(
    getContractAddress('RentalityCarDelivery', 'scripts/deploy_2i_RentalityCarDelivery.js', chainId),
    'RentalityCarDelivery'
  )

  const contract = await ethers.getContractAt('RentalityCarDelivery', delivery)

  console.log(await contract.setDefaultPrices(300, 250))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
