const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
const contract = await ethers.getContractAt('RentalityGateway','0x3Efb1cC1d29010D5BF57384803bb446ea6722722')

    const info  = await contract.getTrip(9)
    console.log(info)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
