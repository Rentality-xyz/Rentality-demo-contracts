const { ethers, network, upgrades } = require('hardhat')
const fs = require('fs')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {

    const [deployer] = await ethers.getSigners()
    const balance = await ethers.provider.getBalance(deployer.address)
  
    const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1

    const rentalityPromoService = checkNotNull(
        getContractAddress('RentalityPromoService', 'scripts/deploy_4f_RentalityPromo.js', chainId),
        'RentalityPromoService'
      )
      
    const contract = await ethers.getContractAt('RentalityPromoService',rentalityPromoService)
    const date = new Date("2025-01-15T23:59:59Z");
    const startDateTime = Math.floor(date.getTime() / 1000);
    const endDate =  new Date("2025-07-31T23:59:59Z")
    const endDateTime = Math.floor(endDate.getTime() / 1000);

    for(let i = 0; i < 10; i++)
    await contract.generateNumbers(10000, 99999, 100, startDateTime, endDateTime,'0x03')

const result= await contract.getPromoCodes() 
const mapped = result.map(code => {
  const parsed = parseInt(code, 16)
return parsed})

const dataToSave = mapped.join('\n');

fs.writeFile('promo/twentyPromo.txt', dataToSave, (err) => {
  if (err) {
    console.error('Error writing to file', err);
  } else {
    console.log('Data successfully saved to output.txt');
  }
});

}
function toSolBytes3(hex) {
 const dif = 6 - hex.length
 let newHex = '';
 for(let i = 0; i < dif; i++)
  newHex += '0'
return '0x' + newHex + hex
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
