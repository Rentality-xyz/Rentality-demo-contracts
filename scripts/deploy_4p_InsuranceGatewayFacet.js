const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('InsuranceGatewayFacet')

  if (chainId < 0) throw new Error('chainId is not set')

  const insuranceQueryFacet1Address = checkNotNull(
    getContractAddress('RentalInsuranceQueryFacet1', 'scripts/deploy_3v_RentalInsuranceQueryFacet1.js', chainId),
    'RentalInsuranceQueryFacet1'
  )
  const insuranceQueryFacet2Address = checkNotNull(
    getContractAddress('RentalInsuranceQueryFacet2', 'scripts/deploy_3x_RentalInsuranceQueryFacet2.js', chainId),
    'RentalInsuranceQueryFacet2'
  )
  const insuranceMainAddress = checkNotNull(
    getContractAddress('RentalInsuranceMain', 'scripts/deploy_3l_RentalInsuranceMain.js', chainId),
    'RentalInsuranceMain'
  )
  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [
    insuranceQueryFacet1Address,
    insuranceQueryFacet2Address,
    insuranceMainAddress,
    rentalityUserServiceAddress,
    notificationServiceAddress,
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
