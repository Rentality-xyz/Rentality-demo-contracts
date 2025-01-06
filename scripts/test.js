const { ethers, network, upgrades } = require('hardhat')
const fs = require('fs')

async function main() {
  const contract = await ethers.getContractAt('RentalityAdminGateway', '0x19dE77342611e0aF6dD387223309B9397123450b')
  console.log(await contract.getRefferalServiceAddress())
  // const Fabric = await ethers.getContractFactory('RentalityPromoService')
  // const contract = await upgrades.deployProxy(Fabric, ['0xE15378Ad98796BB35cbbc116DfC70d3416B52D45'])
  // console.log(await contract.getAddress())
  // //
  // // const contract = await ethers.getContractAt('RentalityPromoService','0xcFF1dD4230AEba815aFc58Fe39A44d9031C700f8')
  // // const startDateTime =  new Date("2025-01-15T23:59:59Z").getSeconds()
  // const date = new Date('2023-01-15T23:59:59Z')
  // const startDateTime = Math.floor(date.getTime() / 1000)
  // const endDate = new Date('2025-07-31T23:59:59Z')
  // const endDateTime = Math.floor(endDate.getTime() / 1000)
  // const prefix = '0xc0'
  // const len = 100
  // console.log(await contract.generateNumbers(1, 10000, 50, startDateTime, endDateTime, 'A'))

  // const result= await contract.getPromoCodes()
  // console.log("codes", result)
  // const mapped = result.map(code => {
  //   const parsed = parseInt(code, 16)
  // return toSolBytes3(parsed.toString(16))})

  // await Promise.all(mapped.map(async (code) => {
  //   console.log(await contract.isActive(code))
  // }
  // ))

  // const promo = fs.readFileSync('promoExists.txt', 'utf8');

  // const promoArray = promo.split('\n').map(code => code.trim());
  // console.log("All PROMOs is uniq: ", new Set(promoArray).keys.length === len)
  // console.log(bytesToString('0x4369aa'))
}
function toSolBytes3(hex) {
  const dif = 6 - hex.length
  let newHex = ''
  for (let i = 0; i < dif; i++) newHex += '0'
  return '0x' + newHex + hex
}

function hexToBytes(hex) {
  hex = hex.startsWith('0x') ? hex.slice(2) : hex

  const bytes = []
  for (let i = 0; i < hex.length; i += 2) {
    bytes.push(parseInt(hex.substr(i, 2), 16))
  }
  return bytes
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
