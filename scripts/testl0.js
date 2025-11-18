const { ethers, upgrades } = require('hardhat')

async function main() {
const rentalitySwaps = await ethers.getContractAt('RentalityTestUSDC', '0x23805809f496FfB869913FF38667F20C39088225')
console.log(await rentalitySwaps.transfer('0xd89c758da61e45eee4770888ebe04372f0d55a6a', BigInt(10000 * 10 ** 6)))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })