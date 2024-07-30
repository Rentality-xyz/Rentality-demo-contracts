const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const {getEmptySearchCarParams} = require("../test/utils");

async function main() {
    let contract = await ethers.getContractAt('IRentalityGateway',"0xCf261b0275870d924d65d67beB9E88Ebd8deE693")
    let params = getEmptySearchCarParams()
    let geo = await ethers.getContractAt('RentalityGeoService','0x2ECb7d9330abA1C47768a374C1f466e4deb9187e')
    let res = await geo.getCarCity(4)
    console.log(res)
    // let result = await contract.searchAvailableCars(Date.now(), Date.now() + 84600, params)
    // console.log(result)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
