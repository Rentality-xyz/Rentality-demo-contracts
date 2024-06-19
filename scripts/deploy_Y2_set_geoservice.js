const RentalityGeoParserJSON_ABI = require('../src/abis/RentalityGeoParser.v0_17_1.abi.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { chainId, deployer } = await startDeploy('')

  if (chainId < 0) throw new Error('chainId is not set')

  const path = buildPath()
  const addressesContractsTestnets = readFileSync(path, 'utf-8')
  const addresses = JSON.parse(addressesContractsTestnets).find(
    (i) => i.chainId === Number(chainId) && i.name === network.name
  )
  if (addresses == null) {
    console.error(`Addresses for chainId:${chainId} was not found in addressesContractsTestnets.json`)
    return
  }

  const rentalityGeoParserAddress = checkNotNull(addresses['RentalityGeoParser'], 'rentalityGeoParserAddress')
  const rentalityGeoServiceAddress = checkNotNull(addresses['RentalityGeoService'], 'rentalityGeoServiceAddress')

  let rentalityGeoParserContract = new ethers.Contract(
    rentalityGeoParserAddress,
    RentalityGeoParserJSON_ABI.abi,
    deployer
  )
  try {
    await rentalityGeoParserContract.setGeoService(rentalityGeoServiceAddress)
    console.log('GeoService was set')
  } catch (e) {
    console.log('GeoService set error:', e)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
