const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_15_0.abi.json')
const { ethers, network } = require('hardhat')
const addressesContractsTestnets = require('./addressesContractsTestnets.json')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { chainId, deployer } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const addresses = addressesContractsTestnets.find((i) => i.chainId === Number(chainId) && i.name === network.name)
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
    return
  }

  const rentalityUserServiceAddress = checkNotNull(addresses['RentalityUserService'], 'rentalityUserServiceAddress')
  const rentalityGatewayAddress = checkNotNull(addresses['RentalityGateway'], 'rentalityGatewayAddress')
  const rentalityTripServiceAddress = checkNotNull(addresses['RentalityTripService'], 'rentalityTripServiceAddress')
  const rentalityPlatformAddress = checkNotNull(addresses['RentalityPlatform'], 'rentalityPlatformAddress')
  const rentalityCarTokenAddress = checkNotNull(addresses['RentalityCarToken'], 'rentalityCarTokenAddress')
  const rentalityEngineAddress = checkNotNull(addresses['RentalityEnginesService'], 'rentalityEngineAddress')
  const rentalityAdminGatewayAddress = checkNotNull(addresses['RentalityAdminGateway'], 'rentalityAdminGatewayAddress')

  let rentalityUserServiceContract = new ethers.Contract(
    rentalityUserServiceAddress,
    RentalityUserServiceJSON_ABI.abi,
    deployer
  )
  try {
    await rentalityUserServiceContract.grantManagerRole(rentalityGatewayAddress)
    await rentalityUserServiceContract.grantManagerRole(rentalityTripServiceAddress)
    await rentalityUserServiceContract.grantManagerRole(rentalityPlatformAddress)
    await rentalityUserServiceContract.grantManagerRole(rentalityCarTokenAddress)
    await rentalityUserServiceContract.grantManagerRole(rentalityAdminGatewayAddress)
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
