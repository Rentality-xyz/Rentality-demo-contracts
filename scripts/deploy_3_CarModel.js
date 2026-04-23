const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { getContractAddress } = require('./utils/contractAddress')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { chainId } = await startDeploy('CarMain')

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
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
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

  const carQueryFacet1Factory = await ethers.getContractFactory('CarQueryFacet1')
  const carQueryFacet1 = await carQueryFacet1Factory.deploy(await carMain.getAddress(), await carQuery.getAddress())
  await carQueryFacet1.waitForDeployment()

  const carMainAddress = await carMain.getAddress()
  const carQueryAddress = await carQuery.getAddress()
  const carQueryFacet1Address = await carQueryFacet1.getAddress()

  console.log(`CarMain was deployed to: ${carMainAddress}`)
  console.log(`CarQuery was deployed to: ${carQueryAddress}`)

  addressSaver(carMainAddress, 'CarMain', true, chainId)
  addressSaver(carQueryAddress, 'CarQuery', true, chainId)
  addressSaver(carQueryFacet1Address, 'CarQueryFacet1', true, chainId)

  await saveJsonAbi('CarMain', chainId, carMain)
  await saveJsonAbi('CarQuery', chainId, carQuery)
  await saveJsonAbi('CarQueryFacet1', chainId, carQueryFacet1)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

