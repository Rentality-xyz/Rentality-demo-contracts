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
 
// base 0xCf261b0275870d924d65d67beB9E88Ebd8deE693
let gatewaty = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')
  console.log(await gatewaty.getTaxesInfoById(53))

  // let paymentService = await ethers.getContractAt('RentalityPaymentService','0x0638e2C99A879eD5D0bA0d6DA7872BD586060FaA')
  // console.log(await paymentService.defineTaxesType('0x5a450aB8C86BA17655a1ACf03114bD3EE986DD4e',1))

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
