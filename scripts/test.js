const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  let engine = await ethers.getContractAt('IRentalityGateway', '0x40ce8A404D513c933F9B8Bbd933CFDa9374A08b3')
  let res = await engine.getTrip(19)
  console.log(res)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
