const package = require('../../package.json')

const pathToAddressFile = 'scripts/addressesContractsTestnets'
const version = extractVersion()
const format = '.json'
function extractVersion() {
  return 'v' + package.version.replace(/\./g, '_')
}
function buildPath() {
  return pathToAddressFile + '.' + version + format
}
module.exports = {
  buildPath,
}
