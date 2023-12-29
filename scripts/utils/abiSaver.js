const fs = require('fs')
const package = require('../../package.json')
const { readFileSync, existsSync } = require('fs')
const { network } = require('hardhat')
var saveJsonAbi = async function(fileName, chainId, contract) {
  const version = extractVersion()


  const onlyAbiJsonData = {
    abi: JSON.parse(contract.interface.formatJson()),
  }


  fs.mkdirSync('./src/abis', { recursive: true }, (err) => {
    if (err) throw err
  })


  let filePath = './src/abis/' + fileName + '.' + version + '.abi.' + '.json'
  fs.writeFileSync(filePath, JSON.stringify(onlyAbiJsonData))
  console.log('JSON abi saved to ' + filePath)

  filePath = updateAddress(fileName, await contract.getAddress())
  console.log('JSON abi saved to ' + filePath)

}

module.exports = saveJsonAbi

function extractVersion() {
  return 'v' + package.version.replace(/\./g, '_')
}

function updateAddress(contractName, newAddress) {
  const v = extractVersion()
  const path = './src/abis/' + contractName + '.' + v + '.addresses.json'
  const chainId = network.config.chainId

  let dataToSave


  const fileExist = existsSync(path)


  if (fileExist) {
    const data = readFileSync(path, 'utf-8')
    const jData = JSON.parse(data)

    const chainIdExist = data.includes(network.config.chainId.toString())
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