const {saveJsonAbi} = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { Role } = require('./utils/consts')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log(`Start script...`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const userServiceContract = await ethers.getContractAt('RentalityUserService', rentalityUserServiceAddress)

  const result = await userServiceContract.manageRole(
    Role.KYCManager,
    '0x84E6e418B55440b8Ae17fd0326BE7f33d1553295',
    true
  )

  console.log(result)

  console.log('Success!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
