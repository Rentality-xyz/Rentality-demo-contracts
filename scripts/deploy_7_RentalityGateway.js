const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')

async function main() {
  const contractName = 'RentalityGateway'
  const [deployer] = await ethers.getSigners()
  const balance = await deployer.getBalance()
  console.log(
    'Deployer address is:',
    deployer.getAddress(),
    ' with balance:',
    balance,
  )

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  const addresses = addressesContractsTestnets.find(
    (i) => i.chainId === chainId,
  )
  if (addresses == null) {
    console.error(
      `Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`,
    )
    return
  }

  const rentalityUtilsAddress = addresses.RentalityUtils
  const rentalityCarTokenAddress = addresses.RentalityCarToken
  const rentalityCurrencyConverterAddress = addresses.RentalityCurrencyConverter
  const rentalityPaymentServiceAddress = addresses.RentalityPaymentService
  const rentalityUserServiceAddress = addresses.RentalityUserService
  const rentalityPlatformAddress = addresses.RentalityPlatform
  const rentalityTripServiceAddress = addresses.RentalityTripService

  if (!rentalityUtilsAddress) {
    console.log('rentalityUtilsAddress is not set')
    return
  }
  if (!rentalityCarTokenAddress) {
    console.log('rentalityCarTokenAddress is not set')
    return
  }
  if (!rentalityPaymentServiceAddress) {
    console.log('rentalityPaymentServiceAddress is not set')
    return
  }
  if (!rentalityCurrencyConverterAddress) {
    console.log('rentalityCurrencyConverterAddress is not set')
    return
  }
  if (!rentalityUserServiceAddress) {
    console.log('rentalityUserServiceAddress is not set')
    return
  }
  if (!rentalityPlatformAddress) {
    console.log('rentalityPlatformAddress is not set')
    return
  }
  if (!rentalityTripServiceAddress) {
    console.log('rentalityTripServiceAddress is not set')
    return
  }

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
  console.log('rentalityPlatformAddress is:', rentalityPlatformAddress)
  console.log('rentalityTripServiceAddress is:', rentalityTripServiceAddress)

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy(
    rentalityCarTokenAddress,
    rentalityCurrencyConverterAddress,
    rentalityTripServiceAddress,
    rentalityUserServiceAddress,
    rentalityPlatformAddress,
    rentalityPaymentServiceAddress
  )
  await contract.deployed()
  console.log(contractName + ' deployed to:', contract.address)

  saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
