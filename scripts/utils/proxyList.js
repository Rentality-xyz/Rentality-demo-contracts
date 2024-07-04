const { extractVersion } = require('./pathBuilder')
const { readFileSync, writeFileSync } = require('fs')
const ProxyList = [
  // 'RentalityPlatform',
  // 'RentalityCarToken',
  // 'RentalityGateway',
  // 'RentalityTripService',
  'RentalityEnginesService',
  'RentalityCarDelivery',
  'RentalityClaimService',
  'RentalityGeoService',
  'RentalityBaseDiscount',
  'RentalityCurrencyConverter',
  'RentalityETHConvertor',
  'RentalityFloridaTaxes',
  'RentalityPaymentService',
  'RentalityUSDTConverter',
  // 'RentalityAdminGateway',
  'RentalityUserService',
  // 'RentalityView'
]

function getChains() {
  let path = 'scripts/addressesContractsTestnets.' + extractVersion() + '.json'
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
  return JSON.parse(data)
}
module.exports = {
  ProxyList,
  getChains,
}
