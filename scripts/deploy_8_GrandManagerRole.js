const RentalityUserServiceJSON_ABI = require('../src/abis/RentalityUserService.v0_2_0.abi.json')
const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { checkNotNull, startDeploy } = require('./utils/deployHelper')

function getOptionalAddress(addresses, key) {
  return addresses[key] || null
}

async function grantPlatformRoleIfPresent(contract, label, user) {
  if (!user) {
    console.log(`${label}: address not found, skipping platform role`)
    return
  }

  const tx = await contract.grantPlatformRole(user)
  console.log(`${label}: platform role tx -> ${tx.hash ?? tx}`)
}

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

  const rentalityUserServiceAddress = checkNotNull(addresses['RentalityUserService'], 'rentalityUserServiceAddress')
  const rentalityUserServiceContract = await ethers.getContractAt(
    RentalityUserServiceJSON_ABI,
    rentalityUserServiceAddress
  )

  const userProfileMainAddress = getOptionalAddress(addresses, 'UserProfileMain')
  const userProfileMainContract = userProfileMainAddress
    ? await ethers.getContractAt('UserProfileMain', userProfileMainAddress)
    : null

  const legacyPlatformCallers = [
    ['Deployer', deployer.address],
    ['RentalityGateway', getOptionalAddress(addresses, 'RentalityGateway')],
    ['RentalityTripService', getOptionalAddress(addresses, 'RentalityTripService')],
    ['CarMain', getOptionalAddress(addresses, 'CarMain')],
    ['CarGatewayAdapter', getOptionalAddress(addresses, 'CarGatewayAdapter')],
    ['AdminGatewayFacet', getOptionalAddress(addresses, 'AdminGatewayFacet')],
    ['RentalityEnginesService', getOptionalAddress(addresses, 'RentalityEnginesService')],
    ['RentalityPaymentService', getOptionalAddress(addresses, 'RentalityPaymentService')],
    ['RentalityCarDelivery', getOptionalAddress(addresses, 'RentalityCarDelivery')],
    ['RentalityClaimService', getOptionalAddress(addresses, 'RentalityClaimService')],
    ['RentalityReferralProgram', getOptionalAddress(addresses, 'RentalityReferralProgram')],
    ['RentalityInvestment', getOptionalAddress(addresses, 'RentalityInvestment')],
    ['CarGatewayFacet', getOptionalAddress(addresses, 'CarGatewayFacet')],
    ['PaymentGatewayFacet', getOptionalAddress(addresses, 'PaymentGatewayFacet')],
    ['InsuranceGatewayFacet', getOptionalAddress(addresses, 'InsuranceGatewayFacet')],
    ['RentalClaimMain', getOptionalAddress(addresses, 'RentalClaimMain')],
  ]

  for (const [label, address] of legacyPlatformCallers) {
    await grantPlatformRoleIfPresent(rentalityUserServiceContract, label, address)
  }

  if (userProfileMainContract) {
    const modelPlatformCallers = [
      ['RentalityGateway', getOptionalAddress(addresses, 'RentalityGateway')],
      ['ProfileGatewayFacet', getOptionalAddress(addresses, 'ProfileGatewayFacet')],
      ['ReferralGatewayFacet', getOptionalAddress(addresses, 'ReferralGatewayFacet')],
      ['InvestmentGatewayFacet', getOptionalAddress(addresses, 'InvestmentGatewayFacet')],
      ['TripGatewayFacet', getOptionalAddress(addresses, 'TripGatewayFacet')],
      ['CarGatewayFacet', getOptionalAddress(addresses, 'CarGatewayFacet')],
      ['CarViewGatewayFacet', getOptionalAddress(addresses, 'CarViewGatewayFacet')],
      ['PaymentGatewayFacet', getOptionalAddress(addresses, 'PaymentGatewayFacet')],
      ['ClaimGatewayFacet', getOptionalAddress(addresses, 'ClaimGatewayFacet')],
      ['InsuranceGatewayFacet', getOptionalAddress(addresses, 'InsuranceGatewayFacet')],
      ['AdminGatewayFacet', getOptionalAddress(addresses, 'AdminGatewayFacet')],
      ['RentalClaimMain', getOptionalAddress(addresses, 'RentalClaimMain')],
    ]

    for (const [label, address] of modelPlatformCallers) {
      await grantPlatformRoleIfPresent(userProfileMainContract, label, address)
    }
  }

  console.log('manager role was granted')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('deploy_8_GrandManagerRole error:', error)
    process.exit(1)
  })
