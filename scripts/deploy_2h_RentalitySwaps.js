const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalitySwaps')

  if (chainId < 0) throw new Error('chainId is not set')

  const isLocalhost = Number(chainId) === 1337
  const userProfileMainAddress = checkNotNull(
    getContractAddress('UserProfileMain', 'scripts/deploy_1h_UserProfileMain.js', chainId),
    'UserProfileMain'
  )
  const router = isLocalhost
    ? ethers.ZeroAddress
    : checkNotNull(getContractAddress('SwapRouterV2', '', chainId), 'SwapRouterV2')
  const weth = isLocalhost
    ? ethers.ZeroAddress
    : checkNotNull(getContractAddress('WETH', '', chainId), 'WETH')
  const allowedToken = isLocalhost
    ? checkNotNull(
        getContractAddress('RentalityTestUSDT', 'scripts/deploy_0a_RentalityTestUSDT.js', chainId),
        'RentalityTestUSDT'
      )
    : checkNotNull(getContractAddress('DefaultAllowedToken', '', chainId), 'DefaultAllowedToken')
  const uniswapFactory = isLocalhost
    ? ethers.ZeroAddress
    : checkNotNull(getContractAddress('UniswapFactory', '', chainId), 'UniswapFactory')

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {},
  })

  const contract = await upgrades.deployProxy(contractFactory, [
    router,
    weth,
    allowedToken,
    userProfileMainAddress,
    uniswapFactory,
  ])
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

