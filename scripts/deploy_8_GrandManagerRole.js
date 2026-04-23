const { ethers, network } = require('hardhat')
const { buildPath } = require('./utils/pathBuilder')
const { readFileSync } = require('fs')

const { startDeploy } = require('./utils/deployHelper')

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

  const userProfileMainAddress = getOptionalAddress(addresses, 'UserProfileMain')
  if (!userProfileMainAddress) {
    throw new Error('UserProfileMain address was not found')
  }
  const userProfileMainContract = await ethers.getContractAt('UserProfileMain', userProfileMainAddress)

  const platformCallers = [
    ['Deployer', deployer.address],
    ['RentalityGateway', getOptionalAddress(addresses, 'RentalityGateway')],
    ['ProfileGatewayFacet', getOptionalAddress(addresses, 'ProfileGatewayFacet')],
    ['ReferralGatewayFacet', getOptionalAddress(addresses, 'ReferralGatewayFacet')],
    ['InvestmentGatewayFacet', getOptionalAddress(addresses, 'InvestmentGatewayFacet')],
    ['TripGatewayFacet', getOptionalAddress(addresses, 'TripGatewayFacet')],
    ['CarGatewayFacet', getOptionalAddress(addresses, 'CarGatewayFacet')],
    ['CarViewGatewayFacet', getOptionalAddress(addresses, 'CarViewGatewayFacet')],
    ['CarViewGatewayFacet1', getOptionalAddress(addresses, 'CarViewGatewayFacet1')],
    ['PaymentGatewayFacet', getOptionalAddress(addresses, 'PaymentGatewayFacet')],
    ['ClaimGatewayFacet', getOptionalAddress(addresses, 'ClaimGatewayFacet')],
    ['InsuranceGatewayFacet', getOptionalAddress(addresses, 'InsuranceGatewayFacet')],
    ['AdminGatewayFacet', getOptionalAddress(addresses, 'AdminGatewayFacet')],
    ['CarMain', getOptionalAddress(addresses, 'CarMain')],
    ['TripMain', getOptionalAddress(addresses, 'TripMain')],
    ['InsuranceMain', getOptionalAddress(addresses, 'InsuranceMain')],
    ['InvestmentMain', getOptionalAddress(addresses, 'InvestmentMain')],
    ['ReferralMain', getOptionalAddress(addresses, 'ReferralMain')],
    ['ReferralMainFacet1', getOptionalAddress(addresses, 'ReferralMainFacet1')],
    ['PaymentMain', getOptionalAddress(addresses, 'PaymentMain')],
    ['PricingMain', getOptionalAddress(addresses, 'PricingMain')],
    ['PricingMainFacet1', getOptionalAddress(addresses, 'PricingMainFacet1')],
    ['RentalityCurrencyConverter', getOptionalAddress(addresses, 'RentalityCurrencyConverter')],
    ['RentalityETHConvertor', getOptionalAddress(addresses, 'RentalityETHConvertor')],
    ['RentalityUSDTConverter', getOptionalAddress(addresses, 'RentalityUSDTConverter')],
    ['RentalitySwaps', getOptionalAddress(addresses, 'RentalitySwaps')],
    ['RentalityPromoService', getOptionalAddress(addresses, 'RentalityPromoService')],
    ['RentalityNotificationService', getOptionalAddress(addresses, 'RentalityNotificationService')],
    ['RentalityGeoService', getOptionalAddress(addresses, 'RentalityGeoService')],
    ['RentalityEnginesService', getOptionalAddress(addresses, 'RentalityEnginesService')],
    ['RentalityDimoService', getOptionalAddress(addresses, 'RentalityDimoService')],
  ]

  for (const [label, address] of platformCallers) {
    await grantPlatformRoleIfPresent(userProfileMainContract, label, address)
  }

  console.log('manager role was granted')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('deploy_8_GrandManagerRole error:', error)
    process.exit(1)
  })
