const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')

async function main() {
 const contract = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

//  const res = await contract.getTripsByUser('0x2729226a14B02D5726821d5a83d7563aCD6D3760')
//  for (let i = 0; i < res.length; i++) {
  const trips = await contract.getTripsAs(true)
  console.log(trips)
//  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
