const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityCurrencyConverter')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityEthService = checkNotNull(
    getContractAddress('RentalityETHConvertor', 'scripts/deploy_2c_RentalityEthService.js', chainId),
    'RentalityETHConvertor'
  )

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const rentalityUsdtService = checkNotNull(
    getContractAddress('RentalityUSDTConverter', 'scripts/deploy_2f_RentalityUsdtService.js', chainId),
    'RentalityUSDTConverter'
  )
  const usdtToken = checkNotNull(
    getContractAddress('RentalityTestUSDT', 'scripts/deploy_0a_RentalityTestUSDT.js', chainId),
    'RentalityTestUSDT'
  )

  const contractFactory = await ethers.getContractFactory(contractName)

  const nativeSymbol = await getNativeSymbol(Number(chainId))
  const contract = await upgrades.deployProxy(contractFactory, [userService, rentalityEthService,nativeSymbol])
  await contract.waitForDeployment()

  await contract.addCurrencyType(usdtToken, rentalityUsdtService, 'USDT')

  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
