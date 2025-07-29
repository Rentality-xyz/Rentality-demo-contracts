const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { ethToken } = require('../test/utils')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  const rentalityConverter = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )

  let contract = await ethers.getContractAt('RentalityCurrencyConverter',rentalityConverter)

  console.log(await contract.removeCurrencyType("0x565df9Ea339318cb31526f65b24139A506d8B82A"))

  console.log(await contract.removeCurrencyType("0x0000000000000000000000000000000000000000"))

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
