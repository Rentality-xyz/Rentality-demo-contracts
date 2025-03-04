const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')
const { emptyLocationInfo } = require('../test/utils')

async function main() {
  const contract = await ethers.getContractAt('IRentalityGateway', '0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

  //  const res = await contract.getTripsByUser('0x2729226a14B02D5726821d5a83d7563aCD6D3760')
  //  for (let i = 0; i < res.length; i++) {
  console.log("contractData: ", contract.interface.encodeFunctionData('searchAvailableCarsWithDelivery',[0, 99999999999, {
    country: '',
    state: '',
    city: '',
    brand: '',
    model: '',
    yearOfProductionFrom: 0,
    yearOfProductionTo: 0,
    pricePerDayInUsdCentsFrom: 0,
    pricePerDayInUsdCentsTo: 0,
    userLocation: emptyLocationInfo,
  }, emptyLocationInfo, emptyLocationInfo]))
  const trips = await contract.searchAvailableCarsWithDelivery(0, 99999999999, {
      country: '',
      state: 'Florida',
      city: '',
      brand: '',
      model: '',
      yearOfProductionFrom: 0,
      yearOfProductionTo: 0,
      pricePerDayInUsdCentsFrom: 0,
      pricePerDayInUsdCentsTo: 0,
      userLocation: emptyLocationInfo,
    }, emptyLocationInfo, emptyLocationInfo)
  console.log(trips)
  //  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
