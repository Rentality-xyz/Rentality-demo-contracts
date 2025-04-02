const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { ethToken } = require('../test/utils')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityAggregator')

  const bnbOracleAddress = '0x3d1E16C26E00A17e3C243330Cc9Ea031C2394c0a'

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )

  const bnbOracleContract = await ethers.getContractAt('AggregatorV3Interface',bnbOracleAddress)
  const decimals = await bnbOracleContract.decimals()
  const description = await bnbOracleContract.description()
  const [roundId, answer, startedAt, updatedAt, answeredInRound] = await bnbOracleContract.latestRoundData()
  console.log(`decimals: ${decimals}, description: ${description}, answer: ${answer}`)




  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [userService, decimals, description, answer])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi('EthToUsdPriceFeedAddress', chainId, contract)

  const bnbService = checkNotNull(
    getContractAddress('RentalityETHConvertor', 'scripts/deploy_2c_RentalityEthService.js', chainId),
    'RentalityETHConvertor'
  )
  

  const bnbContract = await ethers.getContractAt('RentalityETHConvertor', bnbService)
  await bnbContract.setRateFeed(await contract.getAddress())

  const converter = await ethers.getContractAt('RentalityCurrencyConverter', rentalityCurrencyConverterAddress)
  console.log(await converter.addCurrencyType(ethToken, bnbService, 'BNB'))
  console.log(await converter.getFromUsdLatest(ethToken, 10000))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
