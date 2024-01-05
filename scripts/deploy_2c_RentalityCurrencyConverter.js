const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')
const getContractAddress = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')

async function main() {
  var contractName = 'RentalityCurrencyConverter'
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer.address)
  console.log('Deployer address is:', deployer.address, ' with balance:', balance)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  let ethToUsdPriceFeedAddress =
    addressesContractsTestnets.find((i) => i.chainId === chainId)?.EthToUsdPriceFeedAddress ?? ''

  if (chainId === 1337n && ethToUsdPriceFeedAddress.length === 0) {
    contractName = 'RentalityMockPriceFeed'
    let contractFactory = await ethers.getContractFactory(contractName)
    let contract = await contractFactory.deploy(8, 200000000000)
    await contract.waitForDeployment()
    console.log(contractName + ' deployed to:', await contract.getAddress())
    ethToUsdPriceFeedAddress = await contract.getAddress()
  }

  if (!ethToUsdPriceFeedAddress) {
    console.log('ethToUsdPriceFeedAddress is not set')
    return
  }
  console.log('EthToUsdPriceFeedAddress is:', ethToUsdPriceFeedAddress)

  contractName = 'RentalityCurrencyConverter'
  const contractFactory = await ethers.getContractFactory(contractName)

  let userService = getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js')

  const contract = await upgrades.deployProxy(contractFactory, [ethToUsdPriceFeedAddress, userService])
  await contract.waitForDeployment()

  console.log(contractName + ' deployed to:', await contract.getAddress())

  addressSaver(await contract.getAddress(), contractName, true)

  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
