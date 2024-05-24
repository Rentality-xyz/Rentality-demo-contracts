const fs = require('fs')
const path = require('path')
const { checkNotNull } = require('./deployHelper')
const { getContractAddress } = require('./contractAddress')

const pathToContractFolder = './contracts/'
const existingLibs = [
  {
    name: 'RentalityUtils',
    pathToDeploy: './scripts/deploy_1a_RentalityUtils.js',
  },
  {
    name: 'RentalityQuery',
    pathToDeploy: './scripts/deploy_1d_RentalityQuery.js',
  },
  {
    name: 'RealMath',
    pathToDeploy: './scripts/deploy_1c_RealMath.js',
  },
]

const getContractLibs = (contract, chainId) => {
  let libs = {}
  const pathToContract = findContractFile(contract, pathToContractFolder)
  for (let i = 0; i < existingLibs.length; i++) {
    const libName = searchPatternInFile(pathToContract, existingLibs[i].name)
    if (libName === null) continue
    libs[libName] = checkNotNull(getContractAddress(libName, existingLibs[i].pathToDeploy, chainId), libName)
  }
  return libs
}

function findContractFile(contractName, folderPath) {
  const files = fs.readdirSync(folderPath)

  for (const file of files) {
    const filePath = path.join(folderPath, file)

    const stats = fs.statSync(filePath)

    if (stats.isDirectory()) {
      const result = findContractFile(contractName, '.' + path.sep + filePath)
      if (result) {
        return result
      }
    } else {
      if (file.match(contractName) && !file.match('I' + contractName) && !file.match('A' + contractName)) {
        return '.' + path.sep + filePath
      }
    }
  }

  return null
}

function searchPatternInFile(filePath, pattern) {
  try {
    const fileContent = fs.readFileSync(filePath, 'utf-8')

    const match = fileContent.match(new RegExp(pattern + '\\.', 'g'))

    if (match) {
      return pattern
    } else {
      return null
    }
  } catch (error) {
    console.error(`Error reading file: ${error}`)
    return null
  }
}

module.exports = getContractLibs
