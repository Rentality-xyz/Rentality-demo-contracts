const { ethers, upgrades, network } = require('hardhat')
const { readFromFile, getContractAddress } = require('./utils/contractAddress')
const readlineSync = require('readline-sync')
const saveJsonAbi = require('./utils/abiSaver')
const { checkNotNull } = require('./utils/deployHelper')
const getContractLibs = require("./utils/libSearch");
async function main() {
    getContractLibs('RentalityPlatform' ,1337n)


}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
