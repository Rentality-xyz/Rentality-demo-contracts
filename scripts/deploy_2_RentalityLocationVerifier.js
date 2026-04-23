const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const saveJsonAbi = require('./utils/abiSaver')
const { getContractAddress } = require('./utils/contractAddress')
const env = require('hardhat')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityLocationVerifier')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const adminPubkey = process.env.ADMIN_PUBLIC_KEY || (await ethers.getSigners())[0].address

  const contractFactory = await ethers.getContractFactory(contractName)

  const contract = await upgrades.deployProxy(contractFactory, [userService, adminPubkey])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
