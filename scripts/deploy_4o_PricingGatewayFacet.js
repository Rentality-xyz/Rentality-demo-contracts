const saveJsonAbi = require('./utils/abiSaver')
const { upgrades, ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const deploymentName = 'PricingGatewayFacet'
  const implementationName = 'PricingGatewayFacet'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const pricingMainAddress = checkNotNull(
    getContractAddress('PricingMain', 'scripts/deploy_3j_PricingMain.js', chainId),
    'PricingMain'
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
    pricingMainAddress,
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
