const package = require('../../package.json')

const basePathToAddressFile = 'scripts/addressesContractsTestnets'
let featureName = process.env.FEATURE_NAME?.trim()
let pathToAddressFile = featureName ? `${basePathToAddressFile}.${featureName}` : basePathToAddressFile

const version = extractVersion()
const format = '.json'

function extractVersion() {
  return 'v' + package.version.replace(/\./g, '_')
}

function extractReadVersion() {
  let version = process.env.READ_OLD_VERSION
  if (version !== undefined && version.length > 0) {
    return version
  }
  return 'v' + package.version.replace(/\./g, '_')
}

function buildPath() {
  return pathToAddressFile + '.' + version + format
}

function buildPathWithVersion(v = version) {
  if (v !== version)
    return {
      oldPath: pathToAddressFile + '.' + v + format,
      path: pathToAddressFile + '.' + version + format,
    }
  else return { path: pathToAddressFile + '.' + version + format }
}

module.exports = {
  buildPath,
  extractReadVersion,
  buildPathWithVersion,
  extractVersion,
}
