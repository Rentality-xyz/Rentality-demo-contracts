const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_2_0.abi.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { chainId, deployer } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
    return
  }

  const rentalityAdminGatewayAddress = checkNotNull(addresses['RentalityAdminGateway'], 'rentalityAdminGatewayAddress')

  const rentalityInsurance = checkNotNull(
    getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
    'RentalityInsurance'
  )

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
    'RentalityPlatform'
  )
  const adminService = await ethers.getContractAt('RentalityAdminGateway', rentalityAdminGatewayAddress)
  console.log(await adminService.setInsuranceService(rentalityInsurance))

  const platform = await ethers.getContractAt('RentalityView', rentalityPlatformAddress)
  console.log(await platform.updateServiceAddresses(rentalityAdminGatewayAddress))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
