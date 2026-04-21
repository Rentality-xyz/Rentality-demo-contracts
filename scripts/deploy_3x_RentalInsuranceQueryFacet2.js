const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalInsuranceQueryFacet2')

  if (chainId < 0) throw new Error('chainId is not set')

  const insuranceServiceAddress = checkNotNull(
    getContractAddress('RentalityInsurance', 'scripts/deploy_3d_RentalityInsurance.js', chainId),
    'RentalityInsurance'
  )
  const hostInsuranceAddress = checkNotNull(
    getContractAddress('RentalityHostInsurance', 'scripts/deploy_3g_RentalityHostInsurance.js', chainId),
    'RentalityHostInsurance'
  )
  const claimServiceAddress = checkNotNull(
    getContractAddress('RentalityClaimService', 'scripts/deploy_2a_RentalityClaimService.js', chainId),
    'RentalityClaimService'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const userServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const carGatewayAdapterAddress = checkNotNull(
    getContractAddress('CarGatewayAdapter', 'scripts/deploy_3_CarGatewayAdapter.js', chainId),
    'CarGatewayAdapter'
  )
  const currencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy(
    insuranceServiceAddress,
    hostInsuranceAddress,
    claimServiceAddress,
    tripQueryAddress,
    userServiceAddress,
    carGatewayAdapterAddress,
    currencyConverterAddress
  )
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, false, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
