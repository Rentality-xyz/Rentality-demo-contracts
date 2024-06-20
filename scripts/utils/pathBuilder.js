const package = require('../../package.json')

const pathToAddressFile = 'scripts/addressesContractsTestnets'
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
