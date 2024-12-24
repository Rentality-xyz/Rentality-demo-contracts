const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  let contract = await ethers.getContractAt('RentalityPlatform', '0x583Ec73843D491a49AF58DEb49d8E42529591Fb3')
  console.log(await contract.updateServiceAddresses('0x7D2085b25a7Cb1737dF8d1d138790b6EAa981899'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
