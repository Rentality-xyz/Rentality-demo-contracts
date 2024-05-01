const { readFileSync, writeFileSync } = require('fs')
const { network, ethers } = require('hardhat')
const readlineSync = require('readline-sync')
const { spawnSync } = require('child_process')
const { buildPath, extractReadVersion, buildPathWithVersion } = require('./pathBuilder')

function getContractAddress(contractName, addressToDeployScript, chainId) {
  let address = readFromFile(contractName, chainId)

  if (address === null) {
    const message = `Do you want to deploy ${contractName};`
    const silent = process.env.SILENT
    if (silent === undefined || silent === 'false')
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

function readAddress(path, chain, name) {
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
  const jsonData = JSON.parse(data)

  return jsonData.find(
    (el) => el.name === network.name && el.chainId === chain && el[name] !== undefined && el[name] !== ''
  )
}

function readFromFile(contractName, chain) {
  let chainId = Number.parseInt(chain.toString())
  const version = extractReadVersion()
  const { oldPath, path } = buildPathWithVersion(version)
  let contract = readAddress(path, chainId, contractName)
  if (contract === undefined && oldPath === undefined) return null
  else if (contract === undefined) {
    contract = readAddress(oldPath, chainId, contractName)
    if (contract === undefined) return null
  }
  return contract[contractName]
}

module.exports = {
  readFromFile,
  getContractAddress,
}
