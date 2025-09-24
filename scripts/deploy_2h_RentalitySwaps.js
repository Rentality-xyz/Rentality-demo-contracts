const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalitySwaps')

  if (chainId < 0) throw new Error('chainId is not set')

    const rentalityUserServiceAddress = checkNotNull(
        getContractAddress('RentalityUserService', 'scripts/deploy_1b_RentalityUserService.js', chainId),
        'RentalityUserService'
      )
      const router = checkNotNull(
        getContractAddress('SwapRouterV2', '', chainId),
        'SwapRouterV2'
      )
      const weth = checkNotNull(
        getContractAddress('WETH', '', chainId),
        'WETH'
      )
      const allowedToken = checkNotNull(
        getContractAddress('DefaultAllowedToken', '', chainId),
        'DefaultAllowedToken'
      )
      const uniswapFactory = checkNotNull(
        getContractAddress('UniswapFactory', '', chainId),
        'UniswapFactory'
      )
    
      
      const contractFactory = await ethers.getContractFactory(contractName, {
        libraries: {},
      })
    
      const contract = await upgrades.deployProxy(contractFactory, [
        router,
        weth,
        allowedToken,
        rentalityUserServiceAddress,
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
