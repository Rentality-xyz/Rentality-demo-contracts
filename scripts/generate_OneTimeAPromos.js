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
  const date = new Date()
  const startDateTime = Math.floor(date.getTime() / 1000)
  const endDate = new Date('2025-01-25T00:00:01Z')
  const endDateTime = Math.floor(endDate.getTime() / 1000)

  console.log(await contract.generateNumbers(1000, 9999, 5, startDateTime, endDateTime, 'A'))

  const dateGeneral = new Date('2025-01-15T00:00:01Z')
  const startDateTimeGeneral = Math.floor(dateGeneral.getTime() / 1000)
  const endDateGeneral = new Date('2025-07-31T23:59:59Z')
  const endDateTimeGeneral = Math.floor(endDateGeneral.getTime() / 1000)
  console.log(await  contract.generateGeneralCode(startDateTimeGeneral, endDateTimeGeneral))

  const result = await contract.getPromoCodes()


  const filtered = result.filter((code) => code.includes('A'))
  console.log("PROMOS A: ", filtered)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
