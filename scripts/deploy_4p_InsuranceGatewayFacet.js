const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const deploymentName = 'InsuranceGatewayFacet'
  const implementationName = 'InsuranceGatewayFacet'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const insuranceQueryFacet1Address = checkNotNull(
    getContractAddress('InsuranceQueryFacet1', 'scripts/deploy_3v_InsuranceQueryFacet1.js', chainId),
    'InsuranceQueryFacet1'
  )
  const insuranceQueryFacet2Address = checkNotNull(
    getContractAddress('InsuranceQueryFacet2', 'scripts/deploy_3x_InsuranceQueryFacet2.js', chainId),
    'InsuranceQueryFacet2'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
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
    insuranceQueryFacet1Address,
    insuranceQueryFacet2Address,
    insuranceMainAddress,
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
