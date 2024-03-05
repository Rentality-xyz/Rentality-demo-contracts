const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades} = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const readlineSync = require("readline-sync");

async function main() {

    const [deployer] = await ethers.getSigners()


    const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1

    console.log('Recover proxy metadata in chainId:', chainId)

    const contractName = readlineSync.question('Enter contract name to update:\n')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
