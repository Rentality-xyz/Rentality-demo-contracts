const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
 const contract = await ethers.getContractAt('RentalityPaymentService','0xC2AF429e5E8B2bA14a5b448923cb2e512f879Cd9')

 console.log(await contract.setInvestmentService('0xb572D0C0b306305aa845397F72Dc480F6796c49F'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
