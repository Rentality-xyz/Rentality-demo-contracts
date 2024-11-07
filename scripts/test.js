const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let homeLat = '25.623529'
  let homeLon = '-80.343476'
  let pickUpLat = '25.797641'
  let pickUpLon = '-80.202987'

  let locationInfo = {
    latitude: pickUpLat,
    longitude: pickUpLon,
    userAddress: 'Miami Riverwalk, Miami, Florida, USA',
    country: 'USA',
    state: 'Florida',
    city: 'Miami',

    timeZoneId: 'id',
  }
  let locationInfo2 = {
    latitude: homeLat,
    longitude: homeLon,
    userAddress: 'Miami Riverwalk, Miami, Florida, USA',
    country: 'USA',
    state: 'Florida',
    city: 'Miami',

    timeZoneId: 'id',
  }

  let contract = await ethers.getContractAt('IRentalityGateway', '0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

  let res = await contract.searchAvailableCarsWithDelivery(
    0,
    new Date().getSeconds() + 86401,
    getEmptySearchCarParams(0),
    locationInfo,
    locationInfo2
  )
  console.log(res[0].car.pickUp)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
