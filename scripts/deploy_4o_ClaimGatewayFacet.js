const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('ClaimGatewayFacet')

  if (chainId < 0) throw new Error('chainId is not set')

  const claimQueryAddress = checkNotNull(
    getContractAddress('RentalClaimQuery', 'scripts/deploy_3u_RentalClaimQuery.js', chainId),
    'RentalClaimQuery'
  )
  const claimMainAddress = checkNotNull(
    getContractAddress('RentalClaimMain', 'scripts/deploy_3y_RentalClaimMain.js', chainId),
    'RentalClaimMain'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [claimQueryAddress, claimMainAddress, userProfileMainAddress])
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
