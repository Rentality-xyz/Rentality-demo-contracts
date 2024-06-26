const { readFileSync } = require('fs')
const fs = require('fs')
const { network } = require('hardhat')
const { buildPath } = require('./pathBuilder')

module.exports = function addressSaver(contractAddress, contractName, rewriteIfExist, chain) {
  let chainId = Number.parseInt(chain.toString())
  const path = buildPath()
  const data = readFileSync(path, 'utf-8')
  const jsonData = JSON.parse(data)

  const networkName = network.name
  const exist = jsonData.find((element) => element.name === networkName && element.chainId === chainId) != null
  if (exist) {
    jsonData.forEach((element) => {
      if (element.chainId === chainId && element.name === networkName) {
        if (element[contractName] === undefined || element[contractName] === '' || rewriteIfExist) {
          element[contractName] = contractAddress
          fs.writeFileSync(path, JSON.stringify(jsonData, null, 2))
        }
      }
    })
  } else {
    const newNetwork = {
      name: networkName,
      chainId: chainId,
    }
    newNetwork[contractName] = contractAddress
    jsonData.push(newNetwork)
    fs.writeFileSync(path, JSON.stringify(jsonData, null, 2))
  }
}
