const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')

const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
//block 26718122
async function main() {
let contract = await ethers.getContractAt('IRentalityGateway', '0xCf261b0275870d924d65d67beB9E88Ebd8deE693')

let result = await contract.searchAvailableCarsWithDelivery(1722268800, 1722268800, {
}
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
