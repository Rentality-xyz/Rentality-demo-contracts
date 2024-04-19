const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
  let contract = await ethers.getContractAt('RentalityGateway', '0x3Efb1cC1d29010D5BF57384803bb446ea6722722')
  const data = {
    threeDaysDiscount: 100_000,
    sevenDaysDiscount: 200_000,
    thirtyDaysDiscount: 1_000_000,
    initialized: true,
  }
  let tx = await contract.getDiscount('0xC2Fe9c42922C536DFFBA8ffD7b55387BCD1B1dA7')
  console.log(tx)

  //  let contract = await ethers.getContractAt('RentalityPaymentService','0xfa4d535Db0Ea169203422C1771487572bF8B2931')
  // let tx = await contract.changeCurrentDiscountType('0x8B7AB37415a0b14f77A743FEbEd386b65CB7E4FB')
  //  console.log(tx)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
