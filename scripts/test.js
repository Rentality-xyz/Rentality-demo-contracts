const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let contract = await ethers.getContractAt('RentalityInsurance', '0x7E3D4fa52C23f9E5Ee35E757092B0068d7FA5463')
  console.log(await contract.getTripInsurances(170))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
