const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let contract = await ethers.getContractAt('IRentalityGateway', '0x4d2833b206F3A7D8fA6eF0411d5cd7C72905f59B')
  console.log(await contract.setKYCInfo("hello","+380"," ",'0x411b9d47d8dbe1ea9976db867aea2738b4e4010580b109fdea98e20afaa734f3e77cac2c502076c610370f1907bd2ec6c709c83ea02544b353d8bee669b9f001f91c'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
