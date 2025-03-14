const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')
const { emptyLocationInfo } = require('../test/utils')

async function main() {
  const contract = await ethers.getContractAt('RentalityTripService', '0xDB00B0aaD3D43590232280d056DCA49d017A10c2')

 console.log(await contract.getTripsByUser('0xe4496a60CB382F7e71f47692098BcC8b4655cC38'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
