const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const addressSaver = require('./utils/addressSaver')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityEnginesService')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )

  if (network.name === 'hardhat') {
    console.warn('WARNING: might have admin role issue in hardhat network')
  }

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [userService, []])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
