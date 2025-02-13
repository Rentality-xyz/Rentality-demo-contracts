const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityMockPriceFeed')

  // if (chainId !== 1337n) throw new Error('Can be deployed only on chainId: 1337')

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy(6, 100)
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, 'UsdtToUsdPriceFeedAddress', true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
