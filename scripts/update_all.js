const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades, changeNetwork } = require('hardhat')
const { readFromFile } = require('./utils/contractAddress')
const getContractLibs = require('./utils/libSearch')
const { ProxyList } = require('./utils/proxyList')
const { readFileSync, writeFileSync } = require('fs')
const { networks } = require('../hardhat.config')
const { extractVersion } = require('./utils/pathBuilder')
const addressSaver = require('./utils/addressSaver')
const { run } = require('hardhat')

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

/// TODO: change network dynamically
async function update(contractName) {
  const [deployer] = await ethers.getSigners()
  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  const libs = getContractLibs(contractName, chainId)

  console.log('Contract name: ', contractName)

  const contractAddress = readFromFile(contractName, chainId)

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

async function updateGateway(provider, chainId) {
  let contractName = 'RentalityGateway'
  const [deployer] = await ethers.getSigners()

  const balance = await ethers.provider.getBalance(deployer.address)
  console.log('Deployer address is:', await provider.getAddress(), ' with balance:', balance)

  // const chainId = (await provider.provider?.getNetwork())?.chainId ?? -1

  const libs = getContractLibs(contractName, chainId)
  console.log('Contract name: ', contractName)

  const contractAddress = readFromFile(contractName, chainId, name)

  if (contractAddress === null) {
    console.log(`Contract address ${contractName}: not found. Finishing... `)
    process.exit(1)
  }
  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: libs,
  })

  console.log(`Updating contract ${contractName} in address ${contractAddress}`)
  let contract = await upgrades.upgradeProxy(contractAddress, contractFactory, provider)

  contract = await ethers.getContractAt('IRentalityGateway', await contract.getAddress(), provider)
  await saveJsonAbi(contractName, chainId, contract)
}

function getChains() {
  let path = 'scripts/addressesContractsTestnets.' + extractVersion() + '.json'
  let data
  try {
    data = readFileSync(path, 'utf-8')
  } catch (error) {
    if (error.code === 'ENOENT') {
      // File does not exist, create it
      writeFileSync(path, '[]', 'utf-8')
      data = '[]'
    } else {
      throw error
    }
  }
  return JSON.parse(data)
}

async function main() {
  let chains = await getChains()
  for (let i = 0; i < chains.length; i++) {
    let contracts = chains[i]
    // let network = networks[contracts.name]
    // const [deployer] = network.accounts
    /// TODO: remove, change in hardhat config with 'extendEnvironment'
    //         let signer = new ethers.Wallet(deployer, new ethers.JsonRpcProvider(network.url))
    let myNetwork = contracts.name
    const hre = await run('network', { myNetwork: myNetwork })
    // await hre.changeNetwork(contracts.name);
    await deployLib('RentalityUtils')
    await deployLib('RentalityQuery')
    for (let i = 0; i < ProxyList.length; i++) {
      let contract = ProxyList[i]

      if (contract !== 'IRentalityGateway') {
        await update(contract, network.chainId)
      } else {
        await update(network.chainId)
      }
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
