const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { Role } = require('./utils/consts')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log(`Start script...`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const userProfileMainContract = await ethers.getContractAt('UserProfileMain', userProfileMainAddress)

  const result = await userProfileMainContract.manageRole(
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
