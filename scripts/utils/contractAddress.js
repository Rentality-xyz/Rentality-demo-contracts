const { readFileSync } = require('fs')
const { network, ethers } = require('hardhat')
const readlineSync = require('readline-sync')
const { spawnSync } = require('child_process')

const pathToAddressFile = 'scripts/addressesContractsTestnets.json'

function getContractAddress(contractName, addressToDeployScript, chainId) {
  let address = readFromFile(contractName, chainId)

  if (address === null) {
    const message = `Do you want to deploy ${contractName};`
    if (!readlineSync.keyInYNStrict(message)) {
      console.log('Finishing...')
      process.exit(1)
    }
    console.log(`The contract ${contractName} is not deployed. Starting deployment...`)

    const command = 'npx hardhat run ' + addressToDeployScript
    try {
      const result = spawnSync(command, {
        shell: true,
        stdio: 'inherit',
      })

      if (result.error) {
        console.error('Error:', result.error)
        process.exit(1)
      }
      console.log('Deployment finished.')
    } catch (error) {
      console.error('Error:', error)
      process.exit(1)
    }

    address = readFromFile(contractName, chainId)

    if (address === null) {
      throw Error('Fail to deploy contract ' + contractName)
    }
    setTimeout(() => {}, 2000) /// need,
    // because error in case of execution several scripts one by one
  }

  return address
}

function readFromFile(contractName, chain) {
  let chainId = Number.parseInt(chain.toString())
  const data = readFileSync(pathToAddressFile, 'utf-8')
  const jsonData = JSON.parse(data)

  const contract = jsonData.find(
    (el) =>
      el.name === network.name && el.chainId === chainId && el[contractName] !== undefined && el[contractName] !== ''
  )
  return contract === undefined ? null : contract[contractName]
}

module.exports = {
  readFromFile,
  getContractAddress,
}
