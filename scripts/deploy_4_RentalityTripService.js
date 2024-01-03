const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')
const getContractAddress = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')

async function main() {
  const contractName = 'RentalityTripService'
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer)
  console.log(
    'Deployer address is:',
    deployer.getAddress(),
    ' with balance:',
    balance,
  )

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  const rentalityUtilsAddress = getContractAddress(
    'RentalityUtils',
    'scripts/deploy_1a_RentalityUtils.js',
  )

  const rentalityCurrencyConverterAddress = getContractAddress(
    'RentalityCurrencyConverter',
    'scripts/deploy_2c_RentalityCurrencyConverter.js',
  )

  const rentalityCarTokenAddress = getContractAddress(
    'RentalityCarToken',
    'scripts/deploy_3_RentalityCarToken.js',
  )

  const rentalityPaymentServiceAddress = getContractAddress(
    'RentalityPaymentService',
    'scripts/deploy_2d_RentalityPaymentService.js',
  )

  const rentalityUserServiceAddress = getContractAddress(
    'RentalityUserService',
    'scripts/deploy_1b_RentalityUserService.js',
  )

  const engineAddress = getContractAddress(
    'RentalityEnginesService',
    'scripts/deploy_2b_RentalityEngineService.js',
  )

  console.log('rentalityUtilsAddress is:', rentalityUtilsAddress)
  console.log('rentalityCarTokenAddress is:', rentalityCarTokenAddress)
  console.log(
    'rentalityPaymentServiceAddress is:',
    rentalityPaymentServiceAddress,
  )
  console.log(
    'rentalityCurrencyConverterAddress is:',
    rentalityCurrencyConverterAddress,
  )
  console.log('rentalityUserServiceAddress is:', rentalityUserServiceAddress)

  console.log('engineService is: ', engineAddress)

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityUtils: rentalityUtilsAddress,
    },
  })
  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityCurrencyConverterAddress,
    rentalityCarTokenAddress,
    rentalityPaymentServiceAddress,
    rentalityUserServiceAddress,
    engineAddress,
  ])
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
