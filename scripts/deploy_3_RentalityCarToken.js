const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades, network } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')

async function main() {
  const contractName = 'RentalityCarToken'
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer.address)
  console.log('Deployer address is:', await deployer.getAddress(), ' with balance:', balance)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)
  if (chainId < 0) return

  const contractFactory = await ethers.getContractFactory(contractName)

  const geoAddress = getContractAddress('RentalityGeoService', 'scripts/deploy_1c_GeoService.js')

  const engineAddress = getContractAddress('RentalityEnginesService', 'scripts/deploy_2b_RentalityEngineService.js')

  const contract = await upgrades.deployProxy(contractFactory, [geoAddress, engineAddress])
  await contract.waitForDeployment()
  console.log(contractName + ' deployed to:', await contract.getAddress())

  addressSaver(await contract.getAddress(), contractName, true)
  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
