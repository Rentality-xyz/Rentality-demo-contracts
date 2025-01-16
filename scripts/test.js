const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
 const contract = await ethers.getContractAt('RentalityReferralProgram','0xBeF58aBf15D45B9c1e2c18339e2c2Dc9520a5e5D')

 console.log(await contract.getReadyToClaim('0x2729226a14B02D5726821d5a83d7563aCD6D3760'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
