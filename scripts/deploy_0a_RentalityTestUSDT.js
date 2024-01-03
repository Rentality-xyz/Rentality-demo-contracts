const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')

async function main() {
  const contractName = 'RentalityTestUSDT'
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(await deployer.getAddress())
  console.log(
    'Deployer address is:',
    await deployer.getAddress(),
    ' with balance:',
    balance,
  )

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy()
  await contract.waitForDeployment()
  console.log(contractName + ' deployed to:', await contract.getAddress())

  saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
