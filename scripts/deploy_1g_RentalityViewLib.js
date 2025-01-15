const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityViewLib')

  if (chainId < 0) throw new Error('chainId is not set')
    const rentalityUtilsAddress = checkNotNull(
        getContractAddress('RentalityUtils', 'scriptsdeploy_1a_RentalityUtils.js', chainId),
        'RentalityUtils'
      )

      const contractFactory = await ethers.getContractFactory(contractName, {
        libraries: {
          RentalityUtils: rentalityUtilsAddress,
        },
      })
  const contract = await contractFactory.deploy()
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
