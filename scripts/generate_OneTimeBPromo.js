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

  const contract = await ethers.getContractAt('RentalityPromoService', rentalityPromoService)
  const date = new Date('2025-01-15T23:59:59Z')
  const startDateTime = Math.floor(date.getTime() / 1000)
  const endDate = new Date('2025-01-26T00:00:01Z')
  const endDateTime = Math.floor(endDate.getTime() / 1000)

  console.log(await contract.generateNumbers(1000, 9999, 100, startDateTime, endDateTime, 'B'))

  const result = await contract.getPromoCodes()

  const filtered = result.filter((code) => code.includes('B'))
  console.log('Total promos: ', filtered.length)

  const dataToSave = filtered.join('\n')

  fs.writeFileSync('./promo/nintyPromo.txt', dataToSave, (err) => {
    if (err) {
      console.error('Error writing to file', err)
    } else {
      console.log('Data successfully saved to output.txt')
    }
  })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
