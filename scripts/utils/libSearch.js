const fs = require('fs')
const path = require('path')
const { checkNotNull } = require('./deployHelper')
const { getContractAddress } = require('./contractAddress')

const pathToContractFolder = './contracts/'

const buildLibPath = (libName) => {
  return pathToContractFolder + 'libs/' + libName + '.sol'
}
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
  {
    name: 'RentalityTripsQuery',
    pathToDeploy: './scripts/deploy_4b_RentalityView.js',
  },
  {
    name: 'RentalityRefferalLib',
    pathToDeploy: './scripts/deploy_1f_RentalityRefferalLib.js',
  },
  {
    name: 'RentalityViewLib',
    pathToDeploy: './scripts/scripts/deploy_1g_RentalityViewLib.js',
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

    let match = fileContent.match(new RegExp(pattern + '\\.([a-zA-Z_$][a-zA-Z_$0-9]*)', 'g'))

    if (match) {
      let result = match
        .map((value) => value.slice(pattern.length + 1, value.length))
        .find((value) => !isFnInternal(pattern, value))
      if (result !== undefined) return pattern
      return null
    } else {
      return null
    }
  } catch (error) {
    console.error(`Error reading file: ${error}`)
    return null
  }
}

function isFnInternal(libName, fnName) {
  const fileContent = fs.readFileSync(buildLibPath(libName), 'utf-8')

  let indexOfFunction = fileContent.search('function ' + fnName)
  let indexOfBracket = fileContent.indexOf('{', indexOfFunction)

  return fileContent.slice(indexOfFunction, indexOfBracket).includes('internal')
}

module.exports = getContractLibs
