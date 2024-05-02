const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
  let contract = await ethers.getContractAt('RentalityGateway', '0x955DB1170A0E9B9c70F1F206Cc6C24556F09081C')
  let result = await contract.getMyCars()
  console.log(result)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
