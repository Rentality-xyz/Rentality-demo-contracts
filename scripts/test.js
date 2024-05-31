const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let contract = await ethers.getContractAt('RentalityGateway', '0x9C7222781dDe0ac7408286B797b711397b114059')
  let result = await contract.getMyCars()
  console.log(result)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
