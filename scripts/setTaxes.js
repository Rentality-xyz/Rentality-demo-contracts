const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { TaxesLocationType } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityGatewayAddress = checkNotNull(
    getContractAddress('RentalityGateway', 'scripts/deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )
  const adminGatewayFacet = await ethers.getContractAt('IAdminGatewayFacet', rentalityGatewayAddress)

  // Florida
  await adminGatewayFacet.addTaxes('Florida', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 200, tType: 0 },
  ])

  // Alabama
  await adminGatewayFacet.addTaxes('Alabama', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 15_000, tType: 2 },
  ])

  // Alaska
  await adminGatewayFacet.addTaxes('Alaska', TaxesLocationType.State, [
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Arizona
  await adminGatewayFacet.addTaxes('Arizona', TaxesLocationType.State, [
    { name: 'salesTax', value: 56_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Arkansas
  await adminGatewayFacet.addTaxes('Arkansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // California
  await adminGatewayFacet.addTaxes('California', TaxesLocationType.State, [
    { name: 'salesTax', value: 72_500, tType: 2 },
  ])

  // Colorado
  await adminGatewayFacet.addTaxes('Colorado', TaxesLocationType.State, [
    { name: 'salesTax', value: 29_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Connecticut
  await adminGatewayFacet.addTaxes('Connecticut', TaxesLocationType.State, [
    { name: 'salesTax', value: 63_500, tType: 2 },
    { name: 'governmentTax', value: 93_500, tType: 2 },
    { name: 'rentTax', value: 100, tType: 0 },
  ])

  // Delaware
  await adminGatewayFacet.addTaxes('Delaware', TaxesLocationType.State, [
    { name: 'governmentTax', value: 19_900, tType: 2 },
  ])

  // Georgia
  await adminGatewayFacet.addTaxes('Georgia', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Hawaii
  await adminGatewayFacet.addTaxes('Hawaii', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'rentTax', value: 300, tType: 0 },
  ])

  // Idaho
  await adminGatewayFacet.addTaxes('Idaho', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
  ])

  // Illinois
  await adminGatewayFacet.addTaxes('Illinois', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Indiana
  await adminGatewayFacet.addTaxes('Indiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
  ])

  // Iowa
  await adminGatewayFacet.addTaxes('Iowa', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Kansas
  await adminGatewayFacet.addTaxes('Kansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Kentucky
  await adminGatewayFacet.addTaxes('Kentucky', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Louisiana
  await adminGatewayFacet.addTaxes('Louisiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 44_500, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Maine
  await adminGatewayFacet.addTaxes('Maine', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Maryland
  await adminGatewayFacet.addTaxes('Maryland', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 115_000, tType: 2 },
  ])

  // Massachusetts
  await adminGatewayFacet.addTaxes('Massachusetts', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 1_000, tType: 1 },
  ])

  // Michigan
  await adminGatewayFacet.addTaxes('Michigan', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Minnesota
  await adminGatewayFacet.addTaxes('Minnesota', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_750, tType: 2 },
    { name: 'governmentTax', value: 92_000, tType: 2 },
  ])

  // Mississippi
  await adminGatewayFacet.addTaxes('Mississippi', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Missouri
  await adminGatewayFacet.addTaxes('Missouri', TaxesLocationType.State, [
    { name: 'salesTax', value: 42_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Montana
  await adminGatewayFacet.addTaxes('Montana', TaxesLocationType.State, [
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  // Nebraska
  await adminGatewayFacet.addTaxes('Nebraska', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 55_000, tType: 2 },
  ])

  // Nevada
  await adminGatewayFacet.addTaxes('Nevada', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // New Hampshire
  await adminGatewayFacet.addTaxes('New Hampshire', TaxesLocationType.State, [
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // New Jersey
  await adminGatewayFacet.addTaxes('New Jersey', TaxesLocationType.State, [
    { name: 'salesTax', value: 66_250, tType: 2 },
    { name: 'governmentTax', value: 500, tType: 0 },
  ])

  // New Mexico
  await adminGatewayFacet.addTaxes('New Mexico', TaxesLocationType.State, [
    { name: 'salesTax', value: 51_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // New York
  await adminGatewayFacet.addTaxes('New York', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // North Carolina
  await adminGatewayFacet.addTaxes('North Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 47_500, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // North Dakota
  await adminGatewayFacet.addTaxes('North Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Ohio
  await adminGatewayFacet.addTaxes('Ohio', TaxesLocationType.State, [{ name: 'salesTax', value: 57_500, tType: 2 }])

  // Oklahoma
  await adminGatewayFacet.addTaxes('Oklahoma', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Oregon (все налоги 0)
  await adminGatewayFacet.addTaxes('Oregon', TaxesLocationType.State, [])

  // Pennsylvania
  await adminGatewayFacet.addTaxes('Pennsylvania', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 20_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Rhode Island
  await adminGatewayFacet.addTaxes('Rhode Island', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // South Carolina
  await adminGatewayFacet.addTaxes('South Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // South Dakota
  await adminGatewayFacet.addTaxes('South Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 45_000, tType: 2 },
  ])

  // Tennessee
  await adminGatewayFacet.addTaxes('Tennessee', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Texas
  await adminGatewayFacet.addTaxes('Texas', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Utah
  await adminGatewayFacet.addTaxes('Utah', TaxesLocationType.State, [
    { name: 'salesTax', value: 48_500, tType: 2 },
    { name: 'governmentTax', value: 70_000, tType: 2 },
  ])

  // Vermont
  await adminGatewayFacet.addTaxes('Vermont', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // Virginia
  await adminGatewayFacet.addTaxes('Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 43_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Washington
  await adminGatewayFacet.addTaxes('Washington', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 59_000, tType: 2 },
  ])

  // West Virginia
  await adminGatewayFacet.addTaxes('West Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 100, tType: 0 },
  ])

  // Wisconsin
  await adminGatewayFacet.addTaxes('Wisconsin', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  await adminGatewayFacet.addTaxes('Wyoming', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  await adminGatewayFacet.addTaxes('District of Columbia', TaxesLocationType.State, [
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
