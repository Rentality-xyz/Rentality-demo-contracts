const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const deploymentName = 'ClaimGatewayFacet'
  const implementationName = 'AppGatewayFacet9'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const claimQueryAddress = checkNotNull(
    getContractAddress('ReferralQuery', 'scripts/deploy_3o_RentalReferralQuery.js', chainId),
    'ReferralQuery'
  )
  const claimMainAddress = checkNotNull(
    getContractAddress('ReferralMainFacet1', 'scripts/deploy_3n1_ReferralMainFacet1.js', chainId),
    'ReferralMainFacet1'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )

  const contractFactory = await ethers.getContractFactory(implementationName)
  const contract = await upgrades.deployProxy(contractFactory, [claimQueryAddress, claimMainAddress, userProfileMainAddress])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${implementationName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, deploymentName, true, chainId)
  addressSaver(contractAddress, implementationName, true, chainId)
  await saveJsonAbi(deploymentName, chainId, contract)
  await saveJsonAbi(implementationName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
