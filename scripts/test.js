const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { DiamondCutFunctions, ethToken, emptyLocationInfo } = require('../test/utils')
const { keccak256 } = require('hardhat/internal/util/keccak')


async function main() {
  // const contract = await ethers.getContractAt('RentalityUserService','0xE15378Ad98796BB35cbbc116DfC70d3416B52D45')
  // const role = await contract.hasRole(keccak256(Buffer.from('ADMIN_VIEW_ROLE')),'0xE0363c358b1c9F5A31e18BA831204391Cb9451C0')
  // console.log("role ", role)
const bnbContract = await ethers.getContractAt('RentalityAggregator','0x5256c5704e971b206e3bc9dc2836e53ee865d84b')
const latestRaundData = await bnbContract.latestRoundData()

console.log(latestRaundData)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
