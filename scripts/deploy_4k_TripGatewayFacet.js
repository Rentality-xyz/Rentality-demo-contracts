const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const deploymentName = 'TripGatewayFacet'
  const implementationName = 'TripGatewayFacet'
  const { chainId } = await startDeploy(deploymentName)

  if (chainId < 0) throw new Error('chainId is not set')

  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const tripMainFacet1Address = checkNotNull(
    getContractAddress('TripMainFacet1', 'scripts/deploy_3s1_TripMainFacet1.js', chainId),
    'TripMainFacet1'
  )
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )

  const contractFactory = await ethers.getContractFactory(implementationName)
  const contract = await upgrades.deployProxy(contractFactory, [
    tripQueryAddress,
    tripMainFacet1Address,
    userProfileMainAddress,
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




