const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGateway')

  if (chainId < 0) throw new Error('chainId is not set')
  const rentalityRefferalProgram = checkNotNull(
    getContractAddress('RentalityReferralProgram', 'scripts/deploy_3e_RentalityReferralProgram.js', chainId),
    'RentalityReferralProgram'
  )

  const refferalLibAddress = checkNotNull(
    getContractAddress('RentalityRefferalLib', 'scripts/deploy_1f_RentalityRefferalLib.js', chainId),
    'RentalityRefferalLib'
  )
  const contract = await ethers.getContractAt('RentalityReferralProgram', rentalityRefferalProgram)

  console.log(await contract.updateLib(refferalLibAddress))

  console.log('Done!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
