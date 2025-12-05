const { ethers, upgrades } = require('hardhat')

async function main() {
const rentalitySwaps = await ethers.getContractAt('RentalityCurrencyConverter', '0x91C30265daF5Ff11B9151904F363dBA38D1721B5')
console.log(await rentalitySwaps.addCurrencyType('0x23805809f496FfB869913FF38667F20C39088225','0xDC906a5931C7A7c7B671EFa2b8E92C3503C14cEe','USDC'))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })