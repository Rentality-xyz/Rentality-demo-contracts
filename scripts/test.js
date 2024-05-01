const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
  let contract = await ethers.getContractAt('RentalityAdminGateway', '0xF4F37c4a3790Dc3077abfc0A10179a4866919743')
  let res = await contract.updateClaimService('0x98fD825a63221C78E0c2F97586c2CeF5ddeD31c6')
  console.log(res)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
