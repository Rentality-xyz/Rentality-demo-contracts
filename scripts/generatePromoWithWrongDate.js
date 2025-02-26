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
  const date = new Date('2024-01-20T00:00:01Z')
  const startDateTime = Math.floor(date.getTime() / 1000)
  const endDate = new Date('2024-01-26T00:00:01Z')
  const endDateTime = Math.floor(endDate.getTime() / 1000)

  const dataB = fs.readFileSync('./promo/nintyPromo.txt', 'utf8')

  const promoCodesB = dataB
    .split('\n')
    .map((code) => code.trim())
    .filter((code) => code !== '')

  const dataC = fs.readFileSync('./promo/refPromo.txt', 'utf8')

  const promoCodesC = dataC
    .split('\n')
    .map((code) => code.trim())
    .filter((code) => code !== '')

  console.log(await contract.generateNumbers(1000, 9999, 5, startDateTime, endDateTime, 'B'))
  console.log(await contract.generateNumbers(1000, 9999, 5, startDateTime, endDateTime, 'C'))

  const result = await contract.getPromoCodes()

  const filtered = result.filter((code) => code.includes('B') && promoCodesB.includes(code) === false)
  console.log('Total promos: ', filtered.length)

  const dataToSave = filtered.join('\n')

  fs.writeFileSync('./promo/wrongPromo.txt', dataToSave, (err) => {
    if (err) {
      console.error('Error writing to file', err)
    } else {
      console.log('Data successfully saved to output.txt')
    }
  })
  const filteredC = result.filter((code) => code.includes('C') && promoCodesC.includes(code) === false)

  console.log('Total promos: ', filteredC.length)

  const dataToSaveC = filteredC.join('\n')

  fs.writeFileSync('./promo/wrongPromo.txt', dataToSaveC, (err) => {
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
