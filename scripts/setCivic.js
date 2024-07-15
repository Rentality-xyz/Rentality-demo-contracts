const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const addressSaver = require('./utils/addressSaver')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const [deployer] = await ethers.getSigners()
  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const userServiceContract = await ethers.getContractAt('RentalityUserService', userService)
  const result = await userServiceContract.setCivicData(
    '0xF65b6396dF6B7e2D8a6270E3AB6c7BB08BAEF22E',
    process.env.CIVIC_GATEKEEPER_NETWORK
  )
  console.log(result)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
