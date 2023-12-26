const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const { applyProviderWrappers } = require('hardhat/internal/core/providers/construction')
const addressSaver = require('./utils/addressSaver')

async function main() {
  const chainId = network.config.chainId

  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer)
  console.log(
    'Deployer address is:',
    deployer.getAddress(),
    ' with balance:',
    balance,
  )

  let contract

  if (network.name !== 'sepolia') {
    const contractName = 'RentalityGeoMock'

    const contractFactory = await ethers.getContractFactory(contractName)
    contract = await contractFactory.deploy()


  } else {
    const linkToken = '0x779877A7B0D9E8603169DdbD7836e478b4624789'
    const oracle = '0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD'
    const contractName = 'RentalityGeoService'
    const contractFactory = await ethers.getContractFactory(contractName)

    contract = await upgrades.deployProxy(contractFactory, [linkToken, oracle])
  }

  await contract.waitForDeployment()
  const contractName = 'RentalityGeoService'

  console.log(contractName + ' deployed to:', await contract.getAddress())

  await addressSaver(
    await contract.getAddress(),
    contractName,
    true,
  )
  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
