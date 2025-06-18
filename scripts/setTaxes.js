const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const {
  emptyLocationInfo,
  getEmptySearchCarParams,
  taxesWithGovePMM,
  taxesWithoutRentSign,
  taxesWithRentSign,
  encodeTaxes,
  taxesGOVConst,
  TaxesLocationType,
} = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
  const taxesServiceAddress = checkNotNull(
    getContractAddress('RentalityTaxes', 'scripts/deploy_2e_RentalityTaxes.js', chainId),
    'RentalityTaxes'
  )

  const adminGatewayAddress = checkNotNull(
    getContractAddress('RentalityAdminGateway', 'scripts/deploy_6_RentalityAdminGateway.js', chainId),
    'RentalityAdminGateway'
  )
  const paymentsServiceAddress = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )
  const rentalityTripServiceAddress = checkNotNull(
    getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
    'RentalityTripService'
  )
  const contract = await ethers.getContractAt('RentalityTripService', rentalityTripServiceAddress)
  const totalTripsCount = await contract.totalTripCount()

  let paymentsService = await ethers.getContractAt('RentalityPaymentService', paymentsServiceAddress)
  await paymentsService.addTaxesContract (taxesServiceAddress)
  const rentalityAdminGateway = await ethers.getContractAt('RentalityAdminGateway', adminGatewayAddress)

  // Florida
  await rentalityAdminGateway.addTaxes('Florida', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 200, tType: 0 },
  ])

  // Alabama
  await rentalityAdminGateway.addTaxes('Alabama', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 15_000, tType: 2 },
  ])

  // Alaska
  await rentalityAdminGateway.addTaxes('Alaska', TaxesLocationType.State, [
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Arizona
  await rentalityAdminGateway.addTaxes('Arizona', TaxesLocationType.State, [
    { name: 'salesTax', value: 56_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Arkansas
  await rentalityAdminGateway.addTaxes('Arkansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // California
  await rentalityAdminGateway.addTaxes('California', TaxesLocationType.State, [
    { name: 'salesTax', value: 72_500, tType: 2 },
  ])

  // Colorado
  await rentalityAdminGateway.addTaxes('Colorado', TaxesLocationType.State, [
    { name: 'salesTax', value: 29_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Connecticut
  await rentalityAdminGateway.addTaxes('Connecticut', TaxesLocationType.State, [
    { name: 'salesTax', value: 63_500, tType: 2 },
    { name: 'governmentTax', value: 93_500, tType: 2 },
    { name: 'rentTax', value: 100, tType: 0 },
  ])

  // Delaware
  await rentalityAdminGateway.addTaxes('Delaware', TaxesLocationType.State, [
    { name: 'governmentTax', value: 19_900, tType: 2 },
  ])

  // Georgia
  await rentalityAdminGateway.addTaxes('Georgia', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Hawaii
  await rentalityAdminGateway.addTaxes('Hawaii', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'rentTax', value: 300, tType: 0 },
  ])

  // Idaho
  await rentalityAdminGateway.addTaxes('Idaho', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
  ])

  // Illinois
  await rentalityAdminGateway.addTaxes('Illinois', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Indiana
  await rentalityAdminGateway.addTaxes('Indiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
  ])

  // Iowa
  await rentalityAdminGateway.addTaxes('Iowa', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Kansas
  await rentalityAdminGateway.addTaxes('Kansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Kentucky
  await rentalityAdminGateway.addTaxes('Kentucky', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Louisiana
  await rentalityAdminGateway.addTaxes('Louisiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 44_500, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Maine
  await rentalityAdminGateway.addTaxes('Maine', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Maryland
  await rentalityAdminGateway.addTaxes('Maryland', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 115_000, tType: 2 },
  ])

  // Massachusetts
  await rentalityAdminGateway.addTaxes('Massachusetts', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 1_000, tType: 1 },
  ])

  // Michigan
  await rentalityAdminGateway.addTaxes('Michigan', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Minnesota
  await rentalityAdminGateway.addTaxes('Minnesota', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_750, tType: 2 },
    { name: 'governmentTax', value: 92_000, tType: 2 },
  ])

  // Mississippi
  await rentalityAdminGateway.addTaxes('Mississippi', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Missouri
  await rentalityAdminGateway.addTaxes('Missouri', TaxesLocationType.State, [
    { name: 'salesTax', value: 42_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Montana
  await rentalityAdminGateway.addTaxes('Montana', TaxesLocationType.State, [
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  // Nebraska
  await rentalityAdminGateway.addTaxes('Nebraska', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 55_000, tType: 2 },
  ])

  // Nevada
  await rentalityAdminGateway.addTaxes('Nevada', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // New Hampshire
  await rentalityAdminGateway.addTaxes('New Hampshire', TaxesLocationType.State, [
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // New Jersey
  await rentalityAdminGateway.addTaxes('New Jersey', TaxesLocationType.State, [
    { name: 'salesTax', value: 66_250, tType: 2 },
    { name: 'governmentTax', value: 500, tType: 0 },
  ])

  // New Mexico
  await rentalityAdminGateway.addTaxes('New Mexico', TaxesLocationType.State, [
    { name: 'salesTax', value: 51_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // New York
  await rentalityAdminGateway.addTaxes('New York', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // North Carolina
  await rentalityAdminGateway.addTaxes('North Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 47_500, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // North Dakota
  await rentalityAdminGateway.addTaxes('North Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Ohio
  await rentalityAdminGateway.addTaxes('Ohio', TaxesLocationType.State, [
    { name: 'salesTax', value: 57_500, tType: 2 },
  ])

  // Oklahoma
  await rentalityAdminGateway.addTaxes('Oklahoma', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Oregon (все налоги 0)
  await rentalityAdminGateway.addTaxes('Oregon', TaxesLocationType.State, [])

  // Pennsylvania
  await rentalityAdminGateway.addTaxes('Pennsylvania', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 20_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Rhode Island
  await rentalityAdminGateway.addTaxes('Rhode Island', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // South Carolina
  await rentalityAdminGateway.addTaxes('South Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // South Dakota
  await rentalityAdminGateway.addTaxes('South Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 45_000, tType: 2 },
  ])

  // Tennessee
  await rentalityAdminGateway.addTaxes('Tennessee', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Texas
  await rentalityAdminGateway.addTaxes('Texas', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Utah
  await rentalityAdminGateway.addTaxes('Utah', TaxesLocationType.State, [
    { name: 'salesTax', value: 48_500, tType: 2 },
    { name: 'governmentTax', value: 70_000, tType: 2 },
  ])

  // Vermont
  await rentalityAdminGateway.addTaxes('Vermont', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // Virginia
  await rentalityAdminGateway.addTaxes('Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 43_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Washington
  await rentalityAdminGateway.addTaxes('Washington', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 59_000, tType: 2 },
  ])

  // West Virginia
  await rentalityAdminGateway.addTaxes('West Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 100, tType: 0 },
  ])

  // Wisconsin
  await rentalityAdminGateway.addTaxes('Wisconsin', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  await rentalityAdminGateway.addTaxes('Wyoming', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  await rentalityAdminGateway.addTaxes('District of Columbia', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
