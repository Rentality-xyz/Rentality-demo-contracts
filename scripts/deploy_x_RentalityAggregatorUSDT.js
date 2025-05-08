const {saveJsonAbi} = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityAggregator')


  const bnbOracleAddress = '0xD2852dCbEc372aaeDb13E4fa4863fcB17fD89496'

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )

  const usdtOracle = await ethers.getContractAt('AggregatorV3Interface',bnbOracleAddress)
  const decimals = await usdtOracle.decimals()
  const description = await usdtOracle.description()
  const [roundId, answer, startedAt, updatedAt, answeredInRound] = await usdtOracle.latestRoundData()
  console.log(`decimals: ${decimals}, description: ${description}, answer: ${answer}`)


  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [userService, decimals, description, answer])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi('UsdtToUsdPriceFeedAddress', chainId, contract)

  const usdtService = checkNotNull(
    getContractAddress('RentalityUSDTConverter', 'scripts/deploy_2f_RentalityUsdtService.js', chainId),
    'RentalityUSDTConverter'
  )

  const usdt = checkNotNull(
    getContractAddress('RentalityTestUSDT', '', chainId),
    'RentalityTestUSDT'
  )
  const usdtContract = await ethers.getContractAt('RentalityUSDTConverter', usdtService)
  await usdtContract.setRateFeed(await contract.getAddress())

  const converter = await ethers.getContractAt('RentalityCurrencyConverter', rentalityCurrencyConverterAddress)
  console.log(await converter.addCurrencyType(usdt, usdtService, 'USDT'))
  console.log(await converter.getFromUsdLatest(usdt, 10000))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
