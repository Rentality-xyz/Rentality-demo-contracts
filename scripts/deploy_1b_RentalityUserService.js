const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const addresses = require('./addressesContractsTestnets.json')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityUserService')

  if (chainId < 0) throw new Error('chainId is not set')

  const contractFactory = await ethers.getContractFactory(contractName)

  // same for all networks
  const civicGatewayToken = checkNotNull(
    addresses.find((value) => value['CivicGatewayTokenContract'] != null)['CivicGatewayTokenContract'],
    'CivicGatewayTokenContract'
  )
  const civicGatekeeperNetworkId = process.env.CIVIC_GATEKEEPER_NETWORK || 10

  const contract = await upgrades.deployProxy(contractFactory, [civicGatewayToken, civicGatekeeperNetworkId])
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
