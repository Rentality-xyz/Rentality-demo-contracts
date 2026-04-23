const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('InsuranceQueryFacet2')

  if (chainId < 0) throw new Error('chainId is not set')

  const insuranceServiceAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
  )
  const hostInsuranceAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
  )
  const claimServiceAddress = checkNotNull(
    getContractAddress('ReferralMainFacet1', 'scripts/deploy_3n1_ReferralMainFacet1.js', chainId),
    'ReferralMainFacet1'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const userProfileQueryAddress = checkNotNull(
    getContractAddress('UserProfileQuery', 'scripts/deploy_1i_UserProfileQuery.js', chainId),
    'UserProfileQuery'
  )
  const carQueryAddress = checkNotNull(
    getContractAddress('CarQuery', 'scripts/deploy_3_CarModel.js', chainId),
    'CarQuery'
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
    userProfileQueryAddress,
    carQueryAddress,
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
