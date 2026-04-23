const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('PaymentQuery')

  if (chainId < 0) throw new Error('chainId is not set')

  const paymentMainAddress = checkNotNull(
    getContractAddress('PaymentMain', 'scripts/deploy_3h_PaymentMain.js', chainId),
    'PaymentMain'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy(paymentMainAddress)
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
