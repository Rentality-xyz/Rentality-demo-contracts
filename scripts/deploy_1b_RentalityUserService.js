const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const addresses = require('./addressesContractsTestnets.json')
const readlineSync = require('readline-sync')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityUserService')

  if (chainId < 0) throw new Error('chainId is not set')

  const contractFactory = await ethers.getContractFactory(contractName)

  let civicGatewayToken

  if (!readlineSync.keyInYNStrict('Do you want to deploy Mock Civic contract?')) {
    // same for all networks
    civicGatewayToken = checkNotNull(
      addresses.find((value) => {
        const address = value['CivicGatewayTokenContract']
        return address !== undefined && address !== ''
      })['CivicGatewayTokenContract'],
      'CivicGatewayTokenContract'
    )
  } else {
    const mockContractName = 'CivicMockVerifier'

    console.log(`Deploying civic mock contact...`)
    const mockCivicFactory = await ethers.getContractFactory(mockContractName)
    const mockCivic = await mockCivicFactory.deploy()
    await mockCivic.waitForDeployment()

    civicGatewayToken = await mockCivic.getAddress()
    console.log(`${mockContractName} was deployed to: ${civicGatewayToken}`)
    addressSaver(civicGatewayToken, mockContractName, true, chainId)
    console.log()
  }

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
