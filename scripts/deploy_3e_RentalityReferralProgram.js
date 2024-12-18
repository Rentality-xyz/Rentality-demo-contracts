const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityReferralProgram')

  if (chainId < 0) throw new Error('chainId is not set')

  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const refferalLibAddress = checkNotNull(
    getContractAddress('RentalityRefferalLib', 'scripts/deploy_1f_RentalityRefferalLib.js', chainId),
    'RentalityRefferalLib'
  )
  const rentalityCarTokenAddress = checkNotNull(
    getContractAddress('RentalityCarToken', 'scripts/deploy_3_RentalityCarToken.js', chainId),
    'RentalityCarToken'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityRefferalLib: refferalLibAddress,
    },
  })
  const contract = await upgrades.deployProxy(contractFactory, [
    rentalityUserServiceAddress,
    refferalLibAddress,
    rentalityCarTokenAddress,
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
