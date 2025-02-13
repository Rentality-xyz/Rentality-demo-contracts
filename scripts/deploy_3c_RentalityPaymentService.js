const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityPaymentService')

  if (chainId < 0) throw new Error('chainId is not set')

  const userService = checkNotNull(
    getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
    'RentalityUserService'
  )
  const floridaTaxes = checkNotNull(
    getContractAddress('RentalityFloridaTaxes', 'scripts/deploy_2e_RentalityFloridaTaxes.js', chainId),
    'RentalityFloridaTaxes'
  )
  const baseDiscount = checkNotNull(
    getContractAddress('RentalityBaseDiscount', 'scripts/deploy_2g_RentalityBaseDiscount.js', chainId),
    'RentalityBaseDiscount'
  )
  const investService = checkNotNull(
    getContractAddress('RentalityInvestment', 'scripts/deploy_3c_RentalityInvestment.js', chainId),
    'RentalityInvestment'
  )

  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(contractFactory, [userService, floridaTaxes, baseDiscount, investService])
  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
