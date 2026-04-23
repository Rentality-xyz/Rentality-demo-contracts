const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('ReferralClaimQuery')

  if (chainId < 0) throw new Error('chainId is not set')

  const carQueryAddress = checkNotNull(
    getContractAddress('CarQuery', 'scripts/deploy_3_CarModel.js', chainId),
    'CarQuery'
  )
  const rentalityCurrencyConverterAddress = checkNotNull(
    getContractAddress('RentalityCurrencyConverter', 'scripts/deploy_3b_RentalityCurrencyConverter.js', chainId),
    'RentalityCurrencyConverter'
  )
  const tripQueryAddress = checkNotNull(
    getContractAddress('TripQuery', 'scripts/deploy_3t_TripQuery.js', chainId),
    'TripQuery'
  )
  const userProfileQueryAddress = checkNotNull(
    getContractAddress('UserProfileQuery', 'scripts/deploy_1i_UserProfileQuery.js', chainId),
    'UserProfileQuery'
  )
  const claimStoreAddress = checkNotNull(
    getContractAddress('ReferralClaimStore', 'scripts/deploy_2a_RentalClaimStore.js', chainId),
    'ReferralClaimStore'
  )
  const aiDamageAnalyzeAddress = checkNotNull(
    getContractAddress('RentalityAiDamageAnalyzeV2', 'scripts/deploy_3f_RentalityAiDamageAnalyze.js', chainId),
    'RentalityAiDamageAnalyzeV2'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await contractFactory.deploy(
    carQueryAddress,
    rentalityCurrencyConverterAddress,
    tripQueryAddress,
    userProfileQueryAddress,
    claimStoreAddress,
    aiDamageAnalyzeAddress
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
