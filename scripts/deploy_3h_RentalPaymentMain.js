const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('PaymentMain')

  if (chainId < 0) throw new Error('chainId is not set')

  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const investmentMainAddress = checkNotNull(
    getContractAddress('InvestmentMain', 'scripts/deploy_3p_InvestmentMain.js', chainId),
    'InvestmentMain'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('InsuranceMain', 'scripts/deploy_3l_InsuranceMain.js', chainId),
    'InsuranceMain'
  )
  const rentalitySwapsAddress = checkNotNull(
    getContractAddress('RentalitySwaps', 'scripts/deploy_2h_RentalitySwaps.js', chainId),
    'RentalitySwaps'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    userProfileMainAddress,
    userProfileMainAddress,
    investmentMainAddress,
    insuranceMainAddress,
    rentalitySwapsAddress,
  ])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
