const { ethers, upgrades, network } = require('hardhat')
const { readFromFile, getContractAddress } = require('./utils/contractAddress')
const readlineSync = require('readline-sync')
const saveJsonAbi = require('./utils/abiSaver')
const { checkNotNull } = require('./utils/deployHelper')
const contractHasLib = require("./utils/libSearch");
async function main() {
  let path = contractHasLib('RentalityPaymentService','RentalityPaymentService')
    console.log(path)

}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
