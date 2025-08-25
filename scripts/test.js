const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')

const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
//block 26718122
async function main() {
// let contract = await ethers.getContractAt('RentalityAdminGateway', '0x19dE77342611e0aF6dD387223309B9397123450b')

// let investment = await contract.getInvestmentAddress()

// console.log("INVESTMENT: ",investment)
let userAddress = await ethers.getContractAt('RentalityUserService', "0x11027b8F9fD26381AF60E75E3175A5A46C0386e8")

let isInvestor = await userAddress.isInvestorManager("0x4B3b12822b130D0D4d1c5922F1b1D1E916B3031f")

console.log("USER SEIRVCE:", isInvestor)
// const [deployer] = await ethers.getSigners();

// const tx = await deployer.sendTransaction({
//   to: "0x4B3b12822b130D0D4d1c5922F1b1D1E916B3031f",
//   value: ethers.parseEther("0.00001") })

//   await tx.wait();
// console.log("Transaction hash:", tx.hash);

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
