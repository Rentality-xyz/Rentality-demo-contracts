const { ethers, network } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const saveJsonAbi = require('./utils/abiSaver')
const readlineSync = require('readline-sync')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')
const chains = require('../chainIdToEid.json')
/// TODO: create scripts
async function main() {
  const { contractName, chainId } = await startDeploy('RentalityReceiver')
  //
  if (chainId < 0) throw new Error('chainId is not set')
  //
  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  const contractFactory = await ethers.getContractFactory(contractName)
  let eindpoint = '0x6EDCE65403992e310A62460808c4b910D972f10f'

  const rentalityGatewayAddress = checkNotNull(addresses['RentalityGateway'], 'rentalityGatewayAddress')


  let contract = await contractFactory.deploy(rentalityGatewayAddress, eindpoint)
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  const gateway = await ethers.getContractAt("RentalityGateway", rentalityGatewayAddress)
  console.log(await gateway.setLayerZeroSender(contractAddress))
  console.log('Receiver address: ', contractAddress)

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