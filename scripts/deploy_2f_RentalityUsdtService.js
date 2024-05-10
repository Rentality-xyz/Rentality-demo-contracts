const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityUSDTConverter')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  let usdtToken = checkNotNull(
    getContractAddress('RentalityTestUSDT', 'scripts/deploy_0a_RentalityTestUSDT.js', chainId),
    'RentalityTestUSDT'
  )
  const usdtToUsdPriceFeedAddress = checkNotNull(
    getContractAddress('UsdtToUsdPriceFeedAddress', 'scripts/deploy_0c_RentalityMockUsdtPriceFeed.js', chainId),
    'UsdtToUsdPriceFeedAddress'
  )

  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [userService, usdtToken, usdtToUsdPriceFeedAddress])
  await contract.waitForDeployment()
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
