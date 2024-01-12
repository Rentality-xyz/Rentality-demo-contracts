const {ethers, upgrades, network} = require("hardhat");
const readlineSync = require("readline-sync");
const {readFromFile, getContractAddress} = require("./utils/contractAddress");
const saveJsonAbi = require("./utils/abiSaver");

async function main() {
    const linkToken = '0x779877A7B0D9E8603169DdbD7836e478b4624789'
    const oracle = '0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD'

    // console.log(`Deploying RentalityGeoService for sepolia ...`)
    // const contractFactory = await ethers.getContractFactory('RentalityGeoService',
    //     {
    //         libraries:{
    //             "RentalityUtils": getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js')
    //         }
    //     })
    // let contract = await contractFactory.deploy(linkToken, oracle)
    // await contract.waitForDeployment()

  let contract = await ethers.getContractAt('RentalityGeoService',"0x7742a333Cffed2cbceA57578697D435d6aC377Cd")

    console.log("",await contract.getAddress())
    // await contract.executeRequest("Champ de Mars, 5 Avenue Anatole France, 75007 Paris, France","48.858844,2.294350","AIzaSyDhuhAxL2C-JehZvQMRWiJtlU2PUZcZiqE",1);
    await contract.parseGeoResponse(1);
    let timeZoneFrance = await contract.getTimeZoneId(1);
    console.log("France ", timeZoneFrance)

    // Execute request for Kyiv
    // await contract.executeRequest("Maidan Nezalezhnosti, Khreshchatyk Street, Kyiv, Ukraine", "50.4501,30.5234", "AIzaSyDhuhAxL2C-JehZvQMRWiJtlU2PUZcZiqE", 2);

    await contract.parseGeoResponse(2);

    let timeZoneKyiv = await contract.getTimeZoneId(2);
    console.log("Kyiv ", timeZoneKyiv)



}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
