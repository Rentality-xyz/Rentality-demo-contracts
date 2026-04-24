const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const deploymentName = 'ReferralGatewayFacet'
  const implementationName = 'ReferralGatewayFacet'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const referralMainAddress = checkNotNull(
    getContractAddress('ReferralMain', 'scripts/deploy_3n_ReferralMain.js', chainId),
    'ReferralMain'
  )
  const referralMainFacet1Address = checkNotNull(
    getContractAddress('ReferralMainFacet1', 'scripts/deploy_3n1_ReferralMainFacet1.js', chainId),
    'ReferralMainFacet1'
  )
  const referralQueryAddress = checkNotNull(
    getContractAddress('ReferralQuery', 'scripts/deploy_3o_ReferralQuery.js', chainId),
    'ReferralQuery'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const contractFactory = await ethers.getContractFactory(implementationName)
  const contract = await upgrades.deployProxy(contractFactory, [
    referralMainAddress,
    referralMainFacet1Address,
    referralQueryAddress,
    userProfileMainAddress,
    notificationServiceAddress,
  ])
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
