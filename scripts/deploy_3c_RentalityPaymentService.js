const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityPaymentService')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const rentalityTaxes = checkNotNull(
    getContractAddress('RentalityTaxes', 'scripts/deploy_2e_RentalityTaxes.js', chainId),
    'RentalityTaxes'
  )
  const baseDiscount = checkNotNull(
    getContractAddress('RentalityBaseDiscount', 'scripts/deploy_2g_RentalityBaseDiscount.js', chainId),
    'RentalityBaseDiscount'
  )
  const investService = checkNotNull(
    getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
    'RentalityInvestment'
  )

  const rentalityHostInsurace = checkNotNull(
    getContractAddress('RentalityHostInsurance', 'scripts/deploy_3g_RentalityHostInsurance.js', chainId),
    'RentalityHostInsurance'
  )
  const rentalitySwaps = checkNotNull(
    getContractAddress('RentalitySwaps', 'scripts/deploy_2h_RentalitySwaps.js', chainId),
    'RentalitySwaps'
  )

  const quoterV2 = checkNotNull(
    getContractAddress('QuoterV2', '', chainId),
    'QuoterV2'
  )


  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    userService,
    rentalityTaxes,
    baseDiscount,
    investService,
    rentalityHostInsurace,
    rentalitySwaps
  ])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()

  await contract.addTaxes('Florida', [
    { name: 'salesTax', value: 70_000, tType: 2 },
    { name: 'governmentTax', value: 200, tType: 0 },
  ])
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
