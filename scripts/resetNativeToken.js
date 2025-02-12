const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { ethToken } = require('../test/utils')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  const rentalityEthService = checkNotNull(
    getContractAddress('RentalityETHConvertor', 'scripts/deploy_2c_RentalityEthService.js', chainId),
    'RentalityETHConvertor'
  )
  const rentalityUsdtService = checkNotNull(
    getContractAddress('RentalityUSDTConverter', 'scripts/deploy_2f_RentalityUsdtService.js', chainId),
    'RentalityUSDTConverter'
  )
  const usdtToken = checkNotNull(
    getContractAddress('RentalityTestUSDT', 'scripts/deploy_0a_RentalityTestUSDT.js', chainId),
    'RentalityTestUSDT'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const contract = await ethers.getContractAt('RentalityCurrencyConverter',rentalityCurrencyConverterAddress)
  await contract.addCurrencyType(usdtToken, rentalityUsdtService, 'USDT')

  const nativeSymbol = await getNativeSymbol(Number(chainId))
  await contract.addCurrencyType(ethToken, rentalityEthService, nativeSymbol)

  console.log("DONE!")



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
