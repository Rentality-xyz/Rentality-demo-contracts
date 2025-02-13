const fs = require('fs')
const package = require('../../package.json')
const { readFileSync, existsSync } = require('fs')
const { network } = require('hardhat')

const basePathToSave = './src/abis'
let featureName = process.env.FEATURE_NAME?.trim()
let pathToSave = featureName ? `${basePathToSave}/${featureName}` : basePathToSave

var saveJsonAbi = async function (fileName, chainId, contract) {
  let skip = process.env.SKIP_ABI

  if (skip && skip === '1') {
    return
  }
  const version = extractVersion()

  const onlyAbiJsonData = {
    abi: JSON.parse(contract.interface.formatJson()),
  }

  fs.mkdirSync(pathToSave, { recursive: true }, (err) => {
    if (err) throw err
  })

  let filePath = pathToSave + '/' + fileName + '.' + version + '.abi.' + 'json'
  fs.writeFileSync(filePath, JSON.stringify(onlyAbiJsonData))
  console.log('JSON abi saved to ' + filePath)

  filePath = updateAddress(fileName, await contract.getAddress(), chainId)
  console.log('JSON abi saved to ' + filePath)
}

module.exports = saveJsonAbi

function extractVersion() {
  return 'v' + package.version.replace(/\./g, '_')
}

function updateAddress(contractName, newAddress, chain) {
  let chainId = Number.parseInt(chain.toString())
  console.log(chainId)
  const v = extractVersion()
  const path = pathToSave + '/' + contractName + '.' + v + '.addresses.json'

  let dataToSave

  const fileExist = existsSync(path)

  if (fileExist && readFileSync(path, 'utf-8').trim() !== '') {
    const data = readFileSync(path, 'utf-8')
    const jData = JSON.parse(data)

    const chainIdExist = data.includes(chainId.toString())
    if (chainIdExist) {
      jData.addresses.forEach((obj) => {
        if (obj.chainId === chainId) {
          obj.address = newAddress
        }
      })
      dataToSave = jData
    } else {
      jData.addresses.push({
        chainId: chainId,
        address: newAddress,
      })
      dataToSave = jData
    }
  } else {
    dataToSave = {
      addresses: [
        {
          chainId: chainId,
          address: newAddress,
        },
      ],
    }
  }
  fs.writeFileSync(path, JSON.stringify(dataToSave))
  return path
}
