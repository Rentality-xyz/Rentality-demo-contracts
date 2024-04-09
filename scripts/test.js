const { ethers, upgrades, network } = require('hardhat')

async function main() {
  let contract = await ethers.getContractAt('IRentalityGateway', '0x3Efb1cC1d29010D5BF57384803bb446ea6722722')
  let tx = await contract.parseGeoResponse(3)

  // let geo = await ethers.getContractAt("RentalityPaymentService",'0xfa4d535Db0Ea169203422C1771487572bF8B2931'))
  // let geoTx = await geo.setDefaultTax(1)
  // const oneDayInSec = 86400

  // let result2 = await contract.getCarDetails(5)
  console.log(tx)

  //  // console.log(geoTx)
  // let result = await contract.searchAvailableCars(
  //     new Date().getDate(),
  //     new Date().getDate() + oneDayInSec,
  //    getEmptySearchCarParams()
  // )
}
function getEmptySearchCarParams(seed) {
  return {
    country: '',
    state: '',
    city: 'Miami',
    brand: '',
    model: '',
    yearOfProductionFrom: 0,
    yearOfProductionTo: 0,
    pricePerDayInUsdCentsFrom: 0,
    pricePerDayInUsdCentsTo: 0,
  }
}

function getMockCarRequest(seed) {
  const seedStr = seed?.toString() ?? ''
  const seedInt = Number(seed) ?? 0

  const TOKEN_URI = 'TOKEN_URI' + seedStr
  const VIN_NUMBER = 'VIN_NUMBER' + seedStr
  const BRAND = 'BRAND' + seedStr
  const MODEL = 'MODEL' + seedStr
  const YEAR = '200' + seedStr
  const PRICE_PER_DAY = seedInt * 100 + 2
  const DEPOSIT = seedInt * 100 + 3
  const ENGINE_PARAMS = [seedInt * 100 + 4, seedInt * 100 + 5]
  const ETYPE = 1
  const DISTANCE_INCLUDED = seedInt * 100 + 6
  const location = 'Miami Riverwalk, Miami, Florida, USA'
  const locationCoordinates = ' ' + seedInt
  const apiKey = process.env.GOOGLE_API_KEY || ' '
  const timeBufferBetweenTripsInSec = 0
  const locationLatitude = seedStr
  const locationLongitude = seedStr

  return {
    tokenUri: TOKEN_URI,
    carVinNumber: VIN_NUMBER,
    brand: BRAND,
    model: MODEL,
    yearOfProduction: YEAR,
    pricePerDayInUsdCents: PRICE_PER_DAY,
    securityDepositPerTripInUsdCents: DEPOSIT,
    engineParams: ENGINE_PARAMS,
    engineType: ETYPE,
    milesIncludedPerDay: DISTANCE_INCLUDED,
    timeBufferBetweenTripsInSec: timeBufferBetweenTripsInSec,
    locationAddress: location,
    locationLatitude,
    locationLongitude,
    geoApiKey: apiKey,
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
