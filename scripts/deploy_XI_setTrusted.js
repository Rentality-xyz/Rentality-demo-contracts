const { ethers } = require('hardhat')
const { checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')

async function main() {
  const [deployer] = await ethers.getSigners()

  const balance = await ethers.provider.getBalance(deployer.address)
  console.log(`Deployer address is:${await deployer.getAddress()} with balance:${balance}`)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  console.log('ChainId is:', chainId)

  const rentalityGateway = checkNotNull(
    getContractAddress('RentalityGateway', 'scripts/deploy_7_RentalityGateway.js', chainId),
    'RentalityGateway'
  )

  console.log(`Trusted forwarder is resolved by gateway facets through platform role: ${rentalityGateway}`)
  console.log('No legacy RentalityPlatform/RentalityPlatformHelper trusted-forwarder wiring is required')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
