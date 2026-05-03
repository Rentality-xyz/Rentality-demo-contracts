const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityAiDamageAnalyzeV2')

  if (chainId < 0) throw new Error('chainId is not set')

  const userAccessAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const implementationName = 'contracts/test/RentalityAiDamageAnalyzeV2.sol:RentalityAiDamageAnalyzeV2'
  const contractFactory = await ethers.getContractFactory(implementationName)

  const contract = await upgrades.deployProxy(contractFactory, [userAccessAddress])
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
