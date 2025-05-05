const {saveJsonAbi} = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityCarDelivery')

  if (chainId < 0) throw new Error('chainId is not set')

  const realMath = checkNotNull(getContractAddress('RealMath', 'scripts/deploy_1c_RealMath.js', chainId), 'RealMath')
  const rentalityUserServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js', chainId),
    'RentalityUtils'
  )
  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RealMath: realMath,
      RentalityUtils: rentalityUtilsAddress,
    },
  })
  const contract = await upgrades.deployProxy(contractFactory, [rentalityUserServiceAddress])
  await contract.waitForDeployment()

  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
