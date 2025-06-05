const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams, taxesWithGovePMM, taxesWithoutRentSign, taxesWithRentSign, encodeTaxes, taxesGOVConst, TaxesLocationType } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')
  const taxesServiceAddress = checkNotNull(
    getContractAddress('RentalityTaxes', 'scripts/deploy_2e_RentalityTaxes.js', chainId),
    'RentalityTaxes'
  )

  const paymentService = checkNotNull(
    getContractAddress('RentalityPaymentService', 'scripts/deploy_3c_RentalityPaymentService.js', chainId),
    'RentalityPaymentService'
  )
  const rentalityTripServiceAddress = checkNotNull(
    getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
    'RentalityTripService'
  )
  const contract = await ethers.getContractAt('RentalityTripService', rentalityTripServiceAddress)
  const totalTripsCount = await contract.totalTripCount()

    
  const rentalityPaymentService = await ethers.getContractAt('RentalityPaymentService','0xF242A76f700Af65C2D05fB2fa74C99e64e0F299a')
  console.log(await rentalityPaymentService.addTaxesContract(taxesServiceAddress))


  // Florida
await rentalityPaymentService.addTaxes('Florida', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 70_000, tType: 2 },
  { name: "governmentTax", value: 200, tType: 0 }
]);

// Alabama
await rentalityPaymentService.addTaxes('Alabama', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 40_000, tType: 2 },
  { name: "governmentTax", value: 15_000, tType: 2 }
]);

// Alaska
await rentalityPaymentService.addTaxes('Alaska', 
 TaxesLocationType.State,
[
 { name: "governmentTax", value: 100_000, tType: 2 }
]);

// Arizona
await rentalityPaymentService.addTaxes('Arizona', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 56_000, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// Arkansas
await rentalityPaymentService.addTaxes('Arkansas', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 65_000, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);

// California
await rentalityPaymentService.addTaxes('California', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 72_500, tType: 2 }
]);

// Colorado
await rentalityPaymentService.addTaxes('Colorado', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 29_000, tType: 2 },
  { name: "rentTax", value: 200, tType: 0 }
]);

// Connecticut
await rentalityPaymentService.addTaxes('Connecticut', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 63_500, tType: 2 },
  { name: "governmentTax", value: 93_500, tType: 2 },
  { name: "rentTax", value: 100, tType: 0 }
]);

// Delaware
await rentalityPaymentService.addTaxes('Delaware', 
 TaxesLocationType.State,
[
 { name: "governmentTax", value: 19_900, tType: 2 }
]);


// Georgia
await rentalityPaymentService.addTaxes('Georgia', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 40_000, tType: 2 },
  { name: "governmentTax", value: 30_000, tType: 2 }
]);

// Hawaii
await rentalityPaymentService.addTaxes('Hawaii', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 40_000, tType: 2 },
  { name: "rentTax", value: 300, tType: 0 }
]);

// Idaho
await rentalityPaymentService.addTaxes('Idaho', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 }
]);

// Illinois
await rentalityPaymentService.addTaxes('Illinois', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 62_500, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// Indiana
await rentalityPaymentService.addTaxes('Indiana', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 70_000, tType: 2 }
]);

// Iowa
await rentalityPaymentService.addTaxes('Iowa', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// Kansas
await rentalityPaymentService.addTaxes('Kansas', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 65_000, tType: 2 },
  { name: "governmentTax", value: 30_000, tType: 2 }
]);

// Kentucky
await rentalityPaymentService.addTaxes('Kentucky', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 60_000, tType: 2 }
]);

// Louisiana
await rentalityPaymentService.addTaxes('Louisiana', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 44_500, tType: 2 },
  { name: "governmentTax", value: 30_000, tType: 2 }
]);

// Maine
await rentalityPaymentService.addTaxes('Maine', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 55_000, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);

// Maryland
await rentalityPaymentService.addTaxes('Maryland', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 115_000, tType: 2 }
]);

// Massachusetts
await rentalityPaymentService.addTaxes('Massachusetts', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 62_500, tType: 2 },
  { name: "governmentTax", value: 1_000, tType: 1 }
]);

// Michigan
await rentalityPaymentService.addTaxes('Michigan', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 60_000, tType: 2 }
]);

// Minnesota
await rentalityPaymentService.addTaxes('Minnesota', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 68_750, tType: 2 },
  { name: "governmentTax", value: 92_000, tType: 2 }
]);

// Mississippi
await rentalityPaymentService.addTaxes('Mississippi', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 70_000, tType: 2 },
  { name: "governmentTax", value: 60_000, tType: 2 }
]);

// Missouri
await rentalityPaymentService.addTaxes('Missouri', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 42_250, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// Montana
await rentalityPaymentService.addTaxes('Montana', 
 TaxesLocationType.State,
[
 { name: "governmentTax", value: 40_000, tType: 2 }
]);

// Nebraska
await rentalityPaymentService.addTaxes('Nebraska', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 55_000, tType: 2 },
  { name: "governmentTax", value: 55_000, tType: 2 }
]);

// Nevada
await rentalityPaymentService.addTaxes('Nevada', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 68_500, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);

// New Hampshire
await rentalityPaymentService.addTaxes('New Hampshire', 
 TaxesLocationType.State,
[
 { name: "governmentTax", value: 90_000, tType: 2 }
]);

// New Jersey
await rentalityPaymentService.addTaxes('New Jersey', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 66_250, tType: 2 },
  { name: "governmentTax", value: 500, tType: 0 }
]);

// New Mexico
await rentalityPaymentService.addTaxes('New Mexico', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 51_250, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// New York
await rentalityPaymentService.addTaxes('New York', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 40_000, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// North Carolina
await rentalityPaymentService.addTaxes('North Carolina', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 47_500, tType: 2 },
  { name: "governmentTax", value: 80_000, tType: 2 }
]);

// North Dakota
await rentalityPaymentService.addTaxes('North Dakota', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 50_000, tType: 2 },
  { name: "governmentTax", value: 30_000, tType: 2 }
]);

// Ohio
await rentalityPaymentService.addTaxes('Ohio', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 57_500, tType: 2 }
]);

// Oklahoma
await rentalityPaymentService.addTaxes('Oklahoma', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 45_000, tType: 2 },
  { name: "governmentTax", value: 60_000, tType: 2 }
]);

// Oregon (все налоги 0)
await rentalityPaymentService.addTaxes('Oregon', []);

// Pennsylvania
await rentalityPaymentService.addTaxes('Pennsylvania', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 20_000, tType: 2 },
  { name: "rentTax", value: 200, tType: 0 }
]);

// Rhode Island
await rentalityPaymentService.addTaxes('Rhode Island', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 70_000, tType: 2 },
  { name: "governmentTax", value: 80_000, tType: 2 }
]);

// South Carolina
await rentalityPaymentService.addTaxes('South Carolina', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

// South Dakota
await rentalityPaymentService.addTaxes('South Dakota', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 45_000, tType: 2 },
  { name: "governmentTax", value: 45_000, tType: 2 }
]);

// Tennessee
await rentalityPaymentService.addTaxes('Tennessee', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 70_000, tType: 2 },
  { name: "governmentTax", value: 30_000, tType: 2 }
]);

// Texas
await rentalityPaymentService.addTaxes('Texas', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 62_500, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);

// Utah
await rentalityPaymentService.addTaxes('Utah', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 48_500, tType: 2 },
  { name: "governmentTax", value: 70_000, tType: 2 }
]);

// Vermont
await rentalityPaymentService.addTaxes('Vermont', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 90_000, tType: 2 }
]);

// Virginia
await rentalityPaymentService.addTaxes('Virginia', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 43_000, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);

// Washington
await rentalityPaymentService.addTaxes('Washington', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 65_000, tType: 2 },
  { name: "governmentTax", value: 59_000, tType: 2 }
]);

// West Virginia
await rentalityPaymentService.addTaxes('West Virginia', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 100, tType: 0 }
]);

// Wisconsin
await rentalityPaymentService.addTaxes('Wisconsin', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 50_000, tType: 2 },
  { name: "governmentTax", value: 50_000, tType: 2 }
]);

await rentalityPaymentService.addTaxes('Wyoming', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 40_000, tType: 2 },
  { name: "governmentTax", value: 40_000, tType: 2 }
]);

await rentalityPaymentService.addTaxes('District of Columbia', 
 TaxesLocationType.State,
[
 { name: "salesTax", value: 60_000, tType: 2 },
  { name: "governmentTax", value: 100_000, tType: 2 }
]);
 

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
