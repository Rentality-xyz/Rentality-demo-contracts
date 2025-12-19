const { ethers, upgrades } = require('hardhat')

async function main() {
const userService = await ethers.getContractAt('RentalitySender','0x2778796c6349a42A73afc6e2904155024cf6E3fb')
console.log(await userService.setGasLimit(6000000))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })