const { ethers } = require('hardhat')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function callIfExists(label, contract, fnName, arg) {
  const fn = contract[fnName]
  if (typeof fn !== 'function') {
    console.log(`${label}: ${fnName} is not available, skipping`)
    return
  }

  const tx = await fn(arg)
  console.log(`${label}: ${fnName} tx -> ${tx.hash ?? tx}`)
}

async function main() {
  const [deployer] = await ethers.getSigners()

  const balance = await ethers.provider.getBalance(deployer.address)
  console.log(`Deployer address is:${await deployer.getAddress()} with balance:${balance}`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  const rentalityPlatformAddress = checkNotNull(
    getContractAddress('RentalityPlatform', 'scripts/deploy_5_RentalityPlatform.js', chainId),
    'RentalityPlatform'
  )

  const rentalityPlatformHelper = checkNotNull(
    getContractAddress('RentalityPlatformHelper', 'scripts/deploy_4g_RentalityPlatformHelper.js', chainId),
    'RentalityPlatformHelper'
  )

  const rentalityView = checkNotNull(
    getContractAddress('RentalityView', 'scripts/deploy_4c_RentalityView.js', chainId),
    'RentalityView'
  )

  const rentalityTripsView = checkNotNull(
    getContractAddress('RentalityTripsView', 'scripts/deploy_4b_RentalityTripsView.js', chainId),
    'RentalityTripsView'
  )

  const rentalityGateway = checkNotNull(
    getContractAddress('RentalityGateway', 'scripts/deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )

  const platform = await ethers.getContractAt('RentalityPlatform', rentalityPlatformAddress)
  const view = await ethers.getContractAt('RentalityView', rentalityView)
  const platformHelper = await ethers.getContractAt('RentalityPlatformHelper', rentalityPlatformHelper)
  const tripsView = await ethers.getContractAt('RentalityTripsView', rentalityTripsView)

  await callIfExists('RentalityPlatform', platform, 'setTrustedForwarder', rentalityGateway)
  await callIfExists('RentalityView', view, 'setTrustedForwarder', rentalityGateway)
  await callIfExists('RentalityPlatformHelper', platformHelper, 'setTrustedForwarder', rentalityPlatformAddress)
  await callIfExists('RentalityTripsView', tripsView, 'setTrustedForwarder', rentalityView)

  console.log('Trusted forwarder step finished')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
