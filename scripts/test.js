const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let contract = await ethers.getContractAt('RentalityAdminGateway', '0x112CB6d63c40d9078848Db7761459D2335F0312D')
  console.log(await contract.getUserServiceAddress())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
