const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_15_0.abi.json')
const { ethers, network } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')
const net = require('net')

async function main() {
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer)
  console.log(
    'Deployer address is:',
    deployer.getAddress(),
    ' with balance:',
    balance,
  )

  const chainId = network.config.chainId

  const addresses = addressesContractsTestnets.find(
    (i) => i.chainId === chainId && i.name === network.name,
  )
  if (addresses == null) {
    console.error(
      `Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`,
    )
    return
  }

  const rentalityUserServiceAddress = addresses['RentalityUserService']
  const rentalityGatewayAddress = addresses['RentalityGateway']
  const rentalityTripServiceAddress = addresses['RentalityTripService']
  const rentalityPlatformAddress = addresses['RentalityPlatform']
  const rentalityCarTokenAddress = addresses['RentalityCarToken']
  const rentalityEngineAddress = addresses['RentalityEnginesService']
  const rentalityAdminGatewayAddress = addresses['RentalityAdminGateway']

  if (!rentalityUserServiceAddress) {
    console.log('rentalityUserServiceAddress is not set')
    return
  }
  if (!rentalityGatewayAddress) {
    console.log('rentalityAddress is not set')
    return
  }
  if (!rentalityTripServiceAddress) {
    console.log('rentalityTripServiceAddress is not set')
    return
  }
  if (!rentalityPlatformAddress) {
    console.log('rentalityAddress is not set')
    return
  }
  if (!rentalityCarTokenAddress) {
    console.log('rentalityAddress is not set')
    return
  }

  if (!rentalityEngineAddress) {
    console.log('rentalityAddress is not set')
    return
  }
  if (!rentalityAdminGatewayAddress) {
    console.log('rentalityAddress is not set')
    return
  }

  console.log('rentalityUserServiceAddress is:', rentalityUserServiceAddress)
  console.log('rentalityGatewayAddress is:', rentalityGatewayAddress)
  console.log('rentalityTripServiceAddress is:', rentalityTripServiceAddress)
  console.log('rentalityPlatformAddress is:', rentalityPlatformAddress)
  console.log('rentalityCarToken is:', rentalityCarTokenAddress)
  console.log('rentalityEngine service is:', rentalityEngineAddress)
  console.log('rentalityAdminGateway service is:', rentalityAdminGatewayAddress)

  let rentalityUserServiceContract = new ethers.Contract(
    rentalityUserServiceAddress,
    RentalityUserServiceJSON_ABI.abi,
    deployer,
  )
  try {
    await rentalityUserServiceContract.grantManagerRole(rentalityGatewayAddress)
    await rentalityUserServiceContract.grantManagerRole(
      rentalityTripServiceAddress,
    )
    await rentalityUserServiceContract.grantManagerRole(
      rentalityPlatformAddress,
    )
    await rentalityUserServiceContract.grantManagerRole(
      rentalityCarTokenAddress,
    )
    await rentalityUserServiceContract.grantManagerRole(
      rentalityGatewayAddress
    )
    await rentalityUserServiceContract.grantManagerRole(
      rentalityAdminGatewayAddress
    )
    await rentalityUserServiceContract.grantManagerRole(rentalityEngineAddress)
    console.log('manager role granded')
  } catch (e) {
    console.log('grand manager role error:', e)
  }
  //await rentalityUserServiceContract.connect(deployer).grantManagerRole(contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
