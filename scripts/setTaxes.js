const { ethers } = require('hardhat')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { TaxesLocationType } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function addTaxes(pricingGatewayFacet, location, locationType, taxes) {
  const tx = await pricingGatewayFacet.addTaxes(location, locationType, taxes)
  console.log(`${location}: taxes tx -> ${tx.hash ?? tx}`)
  await tx.wait()
}

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityGatewayAddress = checkNotNull(
    getContractAddress('RentalityGateway', 'scripts/deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )
  const pricingGatewayFacet = await ethers.getContractAt('IPricingGatewayFacet', rentalityGatewayAddress)

  // Florida
  await addTaxes(pricingGatewayFacet, 'Florida', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 200, tType: 0 },
  ])

  // Alabama
  await addTaxes(pricingGatewayFacet, 'Alabama', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 15_000, tType: 2 },
  ])

  // Alaska
  await addTaxes(pricingGatewayFacet, 'Alaska', TaxesLocationType.State, [
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Arizona
  await addTaxes(pricingGatewayFacet, 'Arizona', TaxesLocationType.State, [
    { name: 'salesTax', value: 56_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Arkansas
  await addTaxes(pricingGatewayFacet, 'Arkansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // California
  await addTaxes(pricingGatewayFacet, 'California', TaxesLocationType.State, [
    { name: 'salesTax', value: 72_500, tType: 2 },
  ])

  // Colorado
  await addTaxes(pricingGatewayFacet, 'Colorado', TaxesLocationType.State, [
    { name: 'salesTax', value: 29_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Connecticut
  await addTaxes(pricingGatewayFacet, 'Connecticut', TaxesLocationType.State, [
    { name: 'salesTax', value: 63_500, tType: 2 },
    { name: 'governmentTax', value: 93_500, tType: 2 },
    { name: 'rentTax', value: 100, tType: 0 },
  ])

  // Delaware
  await addTaxes(pricingGatewayFacet, 'Delaware', TaxesLocationType.State, [
    { name: 'governmentTax', value: 19_900, tType: 2 },
  ])

  // Georgia
  await addTaxes(pricingGatewayFacet, 'Georgia', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Hawaii
  await addTaxes(pricingGatewayFacet, 'Hawaii', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'rentTax', value: 300, tType: 0 },
  ])

  // Idaho
  await addTaxes(pricingGatewayFacet, 'Idaho', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
  ])

  // Illinois
  await addTaxes(pricingGatewayFacet, 'Illinois', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Indiana
  await addTaxes(pricingGatewayFacet, 'Indiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
  ])

  // Iowa
  await addTaxes(pricingGatewayFacet, 'Iowa', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Kansas
  await addTaxes(pricingGatewayFacet, 'Kansas', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Kentucky
  await addTaxes(pricingGatewayFacet, 'Kentucky', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Louisiana
  await addTaxes(pricingGatewayFacet, 'Louisiana', TaxesLocationType.State, [
    { name: 'salesTax', value: 44_500, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Maine
  await addTaxes(pricingGatewayFacet, 'Maine', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Maryland
  await addTaxes(pricingGatewayFacet, 'Maryland', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 115_000, tType: 2 },
  ])

  // Massachusetts
  await addTaxes(pricingGatewayFacet, 'Massachusetts', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 1_000, tType: 1 },
  ])

  // Michigan
  await addTaxes(pricingGatewayFacet, 'Michigan', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Minnesota
  await addTaxes(pricingGatewayFacet, 'Minnesota', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_750, tType: 2 },
    { name: 'governmentTax', value: 92_000, tType: 2 },
  ])

  // Mississippi
  await addTaxes(pricingGatewayFacet, 'Mississippi', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Missouri
  await addTaxes(pricingGatewayFacet, 'Missouri', TaxesLocationType.State, [
    { name: 'salesTax', value: 42_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // Montana
  await addTaxes(pricingGatewayFacet, 'Montana', TaxesLocationType.State, [
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  // Nebraska
  await addTaxes(pricingGatewayFacet, 'Nebraska', TaxesLocationType.State, [
    { name: 'salesTax', value: 55_000, tType: 2 },
    { name: 'governmentTax', value: 55_000, tType: 2 },
  ])

  // Nevada
  await addTaxes(pricingGatewayFacet, 'Nevada', TaxesLocationType.State, [
    { name: 'salesTax', value: 68_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // New Hampshire
  await addTaxes(pricingGatewayFacet, 'New Hampshire', TaxesLocationType.State, [
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // New Jersey
  await addTaxes(pricingGatewayFacet, 'New Jersey', TaxesLocationType.State, [
    { name: 'salesTax', value: 66_250, tType: 2 },
    { name: 'governmentTax', value: 500, tType: 0 },
  ])

  // New Mexico
  await addTaxes(pricingGatewayFacet, 'New Mexico', TaxesLocationType.State, [
    { name: 'salesTax', value: 51_250, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // New York
  await addTaxes(pricingGatewayFacet, 'New York', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // North Carolina
  await addTaxes(pricingGatewayFacet, 'North Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 47_500, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // North Dakota
  await addTaxes(pricingGatewayFacet, 'North Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Ohio
  await addTaxes(pricingGatewayFacet, 'Ohio', TaxesLocationType.State, [{ name: 'salesTax', value: 57_500, tType: 2 }])

  // Oklahoma
  await addTaxes(pricingGatewayFacet, 'Oklahoma', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 60_000, tType: 2 },
  ])

  // Oregon (все налоги 0)
  await addTaxes(pricingGatewayFacet, 'Oregon', TaxesLocationType.State, [])

  // Pennsylvania
  await addTaxes(pricingGatewayFacet, 'Pennsylvania', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 20_000, tType: 2 },
    { name: 'rentTax', value: 200, tType: 0 },
  ])

  // Rhode Island
  await addTaxes(pricingGatewayFacet, 'Rhode Island', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 80_000, tType: 2 },
  ])

  // South Carolina
  await addTaxes(pricingGatewayFacet, 'South Carolina', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  // South Dakota
  await addTaxes(pricingGatewayFacet, 'South Dakota', TaxesLocationType.State, [
    { name: 'salesTax', value: 45_000, tType: 2 },
    { name: 'governmentTax', value: 45_000, tType: 2 },
  ])

  // Tennessee
  await addTaxes(pricingGatewayFacet, 'Tennessee', TaxesLocationType.State, [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 30_000, tType: 2 },
  ])

  // Texas
  await addTaxes(pricingGatewayFacet, 'Texas', TaxesLocationType.State, [
    { name: 'salesTax', value: 62_500, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Utah
  await addTaxes(pricingGatewayFacet, 'Utah', TaxesLocationType.State, [
    { name: 'salesTax', value: 48_500, tType: 2 },
    { name: 'governmentTax', value: 70_000, tType: 2 },
  ])

  // Vermont
  await addTaxes(pricingGatewayFacet, 'Vermont', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 90_000, tType: 2 },
  ])

  // Virginia
  await addTaxes(pricingGatewayFacet, 'Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 43_000, tType: 2 },
    { name: 'governmentTax', value: 100_000, tType: 2 },
  ])

  // Washington
  await addTaxes(pricingGatewayFacet, 'Washington', TaxesLocationType.State, [
    { name: 'salesTax', value: 65_000, tType: 2 },
    { name: 'governmentTax', value: 59_000, tType: 2 },
  ])

  // West Virginia
  await addTaxes(pricingGatewayFacet, 'West Virginia', TaxesLocationType.State, [
    { name: 'salesTax', value: 60_000, tType: 2 },
    { name: 'governmentTax', value: 100, tType: 0 },
  ])

  // Wisconsin
  await addTaxes(pricingGatewayFacet, 'Wisconsin', TaxesLocationType.State, [
    { name: 'salesTax', value: 50_000, tType: 2 },
    { name: 'governmentTax', value: 50_000, tType: 2 },
  ])

  await addTaxes(pricingGatewayFacet, 'Wyoming', TaxesLocationType.State, [
    { name: 'salesTax', value: 40_000, tType: 2 },
    { name: 'governmentTax', value: 40_000, tType: 2 },
  ])

  await addTaxes(pricingGatewayFacet, 'District of Columbia', TaxesLocationType.State, [
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

