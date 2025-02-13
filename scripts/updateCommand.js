const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')

const { ProxyList, getChains } = require('./utils/proxyList')
const getContractLibs = require('./utils/libSearch')
const addressSaver = require('./utils/addressSaver')
const { bigint } = require('hardhat/internal/core/params/argumentTypes')

async function main() {
  const [deployer] = await ethers.getSigners()
  const balance = await ethers.provider.getBalance(deployer.address)
  console.log(`Deployer address is:${await deployer.getAddress()} with balance:${balance}`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  let contracts = getChains().find((contracts) => BigInt(contracts.chainId) === chainId)
  await deployLib('RentalityUtils')
  await deployLib('RentalityQuery')
  await deployLib('RealMath')
  await deployLib('RentalityTripsQuery')
  await deployLib('RentalityViewLib')
  await deployLib('RentalityRefferalLib')
  for (let i = 0; i < ProxyList.length; i++) {
    let contractName = ProxyList[i]
    let contractAddress = contracts[contractName]

    const libs = getContractLibs(contractName, chainId)

    if (contractAddress === null) {
      console.log(`Contract address ${contractName}: not found. Finishing... `)
      process.exit(1)
    }
    console.log(contractName)
    const contractFactory = await ethers.getContractFactory(contractName, {
      libraries: libs,
    })
    console.log(`Updating contract ${contractName} in address ${contractAddress}`)
    let res = await upgrades.upgradeProxy(contractAddress, contractFactory)
    if (contractName === 'RentalityGateway') res = await ethers.getContractAt('IRentalityGateway', contractAddress)

    await saveJsonAbi(contractName, chainId, res)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
async function deployLib(contractName) {
  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy()
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()
  const [deployer] = await ethers.getSigners()

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
}
