const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull } = require('./utils/deployHelper')

async function main() {
  const [deployer] = await ethers.getSigners()
  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  const userProfileMain = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const userProfileMainContract = await ethers.getContractAt('UserProfileMain', userProfileMain)
  const result = await userProfileMainContract.setCivicData(
    '0xF65b6396dF6B7e2D8a6270E3AB6c7BB08BAEF22E',
    process.env.CIVIC_GATEKEEPER_NETWORK || 10
  )
  console.log(result)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
