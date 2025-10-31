const { ethers, upgrades } = require('hardhat')

async function main() {
// const gatewat = await ethers.getContractAt("RentalitySender",'0x1C97042e54bAa7ba8d58520b855ec67C6Ff4286C')

// console.log(await gatewat.setGasLimit(10_000_000))

console.log((Math.sqrt(4000) * 2 ** 96).toString());

    
}

async function checkError(error) {
const contract = await ethers.getContractAt("ARentalitySender", '0xF103293cffA7a6998Be917DCC1A0174540B418Fc')

console.log(contract.interface.parseError(error.data))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.log(error)
    process.exit(1)
  })