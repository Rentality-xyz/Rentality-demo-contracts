const { ethers } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const tripMainAddress = checkNotNull(
    getContractAddress('TripMain', 'scripts/deploy_3s_TripMain.js', chainId),
    'TripMain'
  )

  const contract = await ethers.getContractAt('TripMain', tripMainAddress)
  console.log('Total trips count: ', await contract.totalSupply())
  console.log(await contract.rebuildUserTrips(1, 0))
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
