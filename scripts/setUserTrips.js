const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

    const rentalityTripServiceAddress = checkNotNull(
        getContractAddress('RentalityTripService', 'scripts/deploy_4_RentalityTripService.js', chainId),
        'RentalityTripService'
      )

      const contract = await ethers.getContractAt('RentalityTripService',rentalityTripServiceAddress)
      console.log('Total trips count: ', await contract.totalTripCount())
      console.log(await contract.setUserTrips(1, 0))
    
  
}