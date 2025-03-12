const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const getNativeSymbol = require('./utils/loadNativeNatworkToken')
const { emptyLocationInfo } = require('../test/utils')

async function main() {
  const contract = await ethers.getContractAt('RentalityInvestment', '0x06059aFF8B3565ff56D7cEb000BAC5bc8865A808')
  const investments = await contract.getAllInvestments();
console.log(investments[0])
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
