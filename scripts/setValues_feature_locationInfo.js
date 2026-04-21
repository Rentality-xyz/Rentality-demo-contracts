const { ethers } = require('hardhat')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const [deployer] = await ethers.getSigners()

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const userProfileMain = await ethers.getContractAt('UserProfileMain', userProfileMainAddress)
  console.log('Start setting kyc message...')
  const res = await userProfileMain.setNewTCMessage(
    'I have read and I agree with Terms of service, Cancellation policy, Prohibited uses and Privacy policy of Rentality.'
  )
  console.log(res)

  const rentalityGeo = checkNotNull(
    getContractAddress('RentalityGeoService', 'deploy_2f_RentalityGeoService.js', chainId),
    'RentalityGeoService'
  )

  const geoService = await ethers.getContractAt('RentalityGeoService', rentalityGeo)

  const rentalityVerifier = checkNotNull(
    getContractAddress('RentalityLocationVerifier', 'scripts/deploy_2_RentalityLocationVerifier.js', chainId),
    'RentalityLocationVerifier'
  )
  console.log('Start setting Location verifier...')
  const result = await geoService.setLocationVerifier(rentalityVerifier)

  console.log(result)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
