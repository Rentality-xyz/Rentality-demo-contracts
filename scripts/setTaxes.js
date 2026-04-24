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
  const pricingGatewayFacet = await ethers.getContractAt('IPricingGatewayFacet', rentalityGatewayAddress)

  // Florida
  await pricingGatewayFacet.addTaxes('Florida', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 200, tType: 0 },
  ])

  // Alabama
  await pricingGatewayFacet.addTaxes('Alabama', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 15_000, tType: 2 },
  ])

  // Alaska
  await pricingGatewayFacet.addTaxes('Alaska', TaxesLocationType.State, [
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Arizona
  await pricingGatewayFacet.addTaxes('Arizona', TaxesLocationType.State, [
    { name: 'salesTax', value: 56_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Arkansas
  await pricingGatewayFacet.addTaxes('Arkansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // California
  await pricingGatewayFacet.addTaxes('California', TaxesLocationType.State, [
    { name: 'salesTax', value: 72_500, tType: 2 },
  ])

  // Colorado
  await pricingGatewayFacet.addTaxes('Colorado', TaxesLocationType.State, [
    { name: 'salesTax', value: 29_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Connecticut
  await pricingGatewayFacet.addTaxes('Connecticut', TaxesLocationType.State, [
    { name: 'salesTax', value: 63_500, tType: 2 },
    { name: 'governmentTax', value: 93_500, tType: 2 },
    { name: 'rentTax', value: 100, tType: 0 },
  ])

  // Delaware
  await pricingGatewayFacet.addTaxes('Delaware', TaxesLocationType.State, [
    { name: 'governmentTax', value: 19_900, tType: 2 },
  ])

  // Georgia
  await pricingGatewayFacet.addTaxes('Georgia', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Hawaii
  await pricingGatewayFacet.addTaxes('Hawaii', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'rentTax', value: 300, tType: 0 },
  ])

  // Idaho
  await pricingGatewayFacet.addTaxes('Idaho', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
  ])

  // Illinois
  await pricingGatewayFacet.addTaxes('Illinois', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Indiana
  await pricingGatewayFacet.addTaxes('Indiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
  ])

  // Iowa
  await pricingGatewayFacet.addTaxes('Iowa', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Kansas
  await pricingGatewayFacet.addTaxes('Kansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Kentucky
  await pricingGatewayFacet.addTaxes('Kentucky', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Louisiana
  await pricingGatewayFacet.addTaxes('Louisiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 44_500, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Maine
  await pricingGatewayFacet.addTaxes('Maine', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Maryland
  await pricingGatewayFacet.addTaxes('Maryland', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 115_000, tType: 2 },
  ])

  // Massachusetts
  await pricingGatewayFacet.addTaxes('Massachusetts', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 1_000, tType: 1 },
  ])

  // Michigan
  await pricingGatewayFacet.addTaxes('Michigan', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Minnesota
  await pricingGatewayFacet.addTaxes('Minnesota', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_750, tType: 2 },
    { name: 'governmentTax', value: 92_000, tType: 2 },
  ])

  // Mississippi
  await pricingGatewayFacet.addTaxes('Mississippi', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Missouri
  await pricingGatewayFacet.addTaxes('Missouri', TaxesLocationType.State, [
    { name: 'salesTax', value: 42_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Montana
  await pricingGatewayFacet.addTaxes('Montana', TaxesLocationType.State, [
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  // Nebraska
  await pricingGatewayFacet.addTaxes('Nebraska', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 55_000, tType: 2 },
  ])

  // Nevada
  await pricingGatewayFacet.addTaxes('Nevada', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // New Hampshire
  await pricingGatewayFacet.addTaxes('New Hampshire', TaxesLocationType.State, [
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // New Jersey
  await pricingGatewayFacet.addTaxes('New Jersey', TaxesLocationType.State, [
    { name: 'salesTax', value: 66_250, tType: 2 },
    { name: 'governmentTax', value: 500, tType: 0 },
  ])

  // New Mexico
  await pricingGatewayFacet.addTaxes('New Mexico', TaxesLocationType.State, [
    { name: 'salesTax', value: 51_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // New York
  await pricingGatewayFacet.addTaxes('New York', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // North Carolina
  await pricingGatewayFacet.addTaxes('North Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 47_500, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // North Dakota
  await pricingGatewayFacet.addTaxes('North Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Ohio
  await pricingGatewayFacet.addTaxes('Ohio', TaxesLocationType.State, [{ name: 'salesTax', value: 57_500, tType: 2 }])

  // Oklahoma
  await pricingGatewayFacet.addTaxes('Oklahoma', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Oregon (все налоги 0)
  await pricingGatewayFacet.addTaxes('Oregon', TaxesLocationType.State, [])

  // Pennsylvania
  await pricingGatewayFacet.addTaxes('Pennsylvania', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 20_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Rhode Island
  await pricingGatewayFacet.addTaxes('Rhode Island', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // South Carolina
  await pricingGatewayFacet.addTaxes('South Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // South Dakota
  await pricingGatewayFacet.addTaxes('South Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 45_000, tType: 2 },
  ])

  // Tennessee
  await pricingGatewayFacet.addTaxes('Tennessee', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Texas
  await pricingGatewayFacet.addTaxes('Texas', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Utah
  await pricingGatewayFacet.addTaxes('Utah', TaxesLocationType.State, [
    { name: 'salesTax', value: 48_500, tType: 2 },
    { name: 'governmentTax', value: 70_000, tType: 2 },
  ])

  // Vermont
  await pricingGatewayFacet.addTaxes('Vermont', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // Virginia
  await pricingGatewayFacet.addTaxes('Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 43_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Washington
  await pricingGatewayFacet.addTaxes('Washington', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 59_000, tType: 2 },
  ])

  // West Virginia
  await pricingGatewayFacet.addTaxes('West Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 100, tType: 0 },
  ])

  // Wisconsin
  await pricingGatewayFacet.addTaxes('Wisconsin', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  await pricingGatewayFacet.addTaxes('Wyoming', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  await pricingGatewayFacet.addTaxes('District of Columbia', TaxesLocationType.State, [
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
