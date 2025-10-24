const { ethers, upgrades } = require('hardhat')

async function main() {
const gatewat = await ethers.getContractAt("RentalityGateway",'0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

console.log(await gatewat.setLayerZeroSender("0x335cA50Fe7CB4e06a1708e599644361e45F5B153"))


    
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