const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { chainId } = await startDeploy('CarGatewayAdapter')

  if (chainId < 0) throw new Error('chainId is not set')

  const geoAddress = checkNotNull(
    getContractAddress('RentalityGeoService', 'scripts/deploy_2f_RentalityGeoService.js', chainId),
    'RentalityGeoService'
  )

  const engineAddress = checkNotNull(
    getContractAddress('RentalityEnginesService', 'scripts/deploy_2b_RentalityEngineService.js', chainId),
    'RentalityEnginesService'
  )

  const userServiceAddress = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )

  const notificationServiceAddress = checkNotNull(
    getContractAddress('RentalityNotificationService', 'scripts/deploy_2_RentalityNotificationService.js', chainId),
    'RentalityNotificationService'
  )

  const carMainFactory = await ethers.getContractFactory('CarMain')
  const carMain = await upgrades.deployProxy(
    carMainFactory,
    [geoAddress, engineAddress, userServiceAddress, notificationServiceAddress],
    { unsafeAllow: ['constructor'] }
  )
  await carMain.waitForDeployment()

  const carQueryFactory = await ethers.getContractFactory('CarQuery')
  const carQuery = await carQueryFactory.deploy(await carMain.getAddress())
  await carQuery.waitForDeployment()

  const adapterFactory = await ethers.getContractFactory('CarGatewayAdapter')
  const carGatewayAdapter = await adapterFactory.deploy(await carMain.getAddress(), await carQuery.getAddress())
  await carGatewayAdapter.waitForDeployment()

  const carMainAddress = await carMain.getAddress()
  const carQueryAddress = await carQuery.getAddress()
  const carGatewayAdapterAddress = await carGatewayAdapter.getAddress()

  console.log(`CarMain was deployed to: ${carMainAddress}`)
  console.log(`CarQuery was deployed to: ${carQueryAddress}`)
  console.log(`CarGatewayAdapter was deployed to: ${carGatewayAdapterAddress}`)

  addressSaver(carMainAddress, 'CarMain', true, chainId)
  addressSaver(carQueryAddress, 'CarQuery', true, chainId)
  addressSaver(carGatewayAdapterAddress, 'CarGatewayAdapter', true, chainId)

  await saveJsonAbi('CarMain', chainId, carMain)
  await saveJsonAbi('CarQuery', chainId, carQuery)
  await saveJsonAbi('CarGatewayAdapter', chainId, carGatewayAdapter)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
