const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')

async function main() {
    const contract = await ethers.getContractAt('RentalityInvestment','0x670E8e167830121Bb74BC1D94116Fb0b25E036c6')
    let res = await contract.getAllInvestments()
    console.log(res)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
