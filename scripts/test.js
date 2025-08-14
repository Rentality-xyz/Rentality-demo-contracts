const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')
const { Actions, V4Planner } = require('@uniswap/v4-sdk')
  const { CommandType, RoutePlanner } = require('@uniswap/universal-router-sdk')
  const { Pool } =  require('@uniswap/v4-sdk')
const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
//block 26718122
async function main() {

     let config = {
  poolKey: {
      currency0: linkToken,
      currency1: ethToken,
      fee: 500,
      tickSpacing: 10,
      hooks: await contract.getAddress(),
  },
  zeroForOne: true,
  amountIn: amountIn, 
  amountOutMinimum: "minAmountOut",
  hookData: data
}

const poolAddress = Pool.getAddress(
  CurrentConfig.pool.token0, 
  CurrentConfig.pool.token1, 
  CurrentConfig.pool.fee
)

  let info = await Pool.getPoolKey()
//   const [deployer] = await ethers.getSigners()
//   const contractFactory = await ethers.getContractFactory('AccessSenderHook')
//   let linkToken = "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
//   let amountIn = 25000;
//   let poolManager = "	0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
//   let weth = "0x4200000000000000000000000000000000000006"

 
//   console.log('AccessSenderHook deployed to:', await contract.getAddress())

// let rentalityGateway = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

// let contract =  await contractFactory.deploy(poolManager, weth, await rentalityGateway.getAddress())
// let data = rentalityGateway.interface.encodeFunctionData('payKycCommission', [zeroHash])

//    let config = {
//   poolKey: {
//       currency0: linkToken,
//       currency1: ethToken,
//       fee: 500,
//       tickSpacing: 10,
//       hooks: await contract.getAddress(),
//   },
//   zeroForOne: true,
//   amountIn: amountIn, 
//   amountOutMinimum: "minAmountOut",
//   hookData: data
// }
//   const v4Planner = new V4Planner()
//   const routePlanner = new RoutePlanner()
  
//   // Set deadline (1 hour from now)
//   const deadline = Math.floor(Date.now() / 1000) + 3600
  
//   v4Planner.addAction(Actions.SWAP_EXACT_IN_SINGLE, [config]);
//   v4Planner.addAction(Actions.SETTLE_ALL, [config.poolKey.currency0, CurrentConfig.amountIn]);
//   v4Planner.addAction(Actions.TAKE_ALL, [config.poolKey.currency1, CurrentConfig.amountOutMinimum]);
//   const encodedActions = v4Planner.finalize()
  
//   routePlanner.addCommand(CommandType.V4_SWAP, [v4Planner.actions, v4Planner.params])
  

  
//   const tx = await universalRouter.execute(
//       routePlanner.commands,
//       [encodedActions],
//       deadline,
//       {}
//   )
  
//   const receipt = await tx.wait()
//   console.log('Swap completed! Transaction hash:', receipt.transactionHash)

//   console.log(await approvetx.wait())




}

function encodeSqrtPriceX96(price) {
  return JSBI.BigInt(Math.floor(Math.sqrt(price) * Math.pow(2, 96)));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
