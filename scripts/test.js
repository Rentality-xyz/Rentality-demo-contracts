const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')
// const { Actions, V4Planner } = require('@uniswap/v4-sdk')
//   const { CommandType, RoutePlanner } = require('@uniswap/universal-router-sdk')
const { Pool } = require('@uniswap/v4-sdk');
const { Token } = require('@uniswap/sdk-core')
const { deploy } = require('@openzeppelin/hardhat-upgrades/dist/utils')
const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
const STATE_VIEW_ADDRESS = '0x571291b572ed32ce6751a2cb2486ebee8defb9b4'
const STATE_VIEW_ABI = 
[
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "poolId",
        "type": "bytes32"
      }
    ],
    "name": "getLiquidity",
    "outputs": [
      { "internalType": "uint128", "name": "liquidity", "type": "uint128" }
    ],
    "stateMutability": "view",
    "type": "function"
  }
];


//block 26718122
async function main() {


  // const deployer = await ethers.getSigner()
  const contractFactory = await ethers.getContractFactory('AccessSenderHook')
  let linkToken = "0xe4ab69c077896252fafbd49efd26b5d171a32410"
  let amountIn = 25000;
  let poolManager = "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
  // let usdc = "0x14196f08a4fa0b66b7331bc40dd6bcd8a1deea9f"
  let weth = "0x4200000000000000000000000000000000000006"

let config = {
  poolKey: {
      currency0: linkToken.trim(),
      currency1: weth.trim(),
      fee: 3000,
      tickSpacing: 60,
      hooks: weth,
  },
  zeroForOne: true,
  amountIn: amountIn, 
  amountOutMinimum: 0,
  hookData: '0x000'
}
let tokenLink = new Token(84532,linkToken, 6)
let weiToken = new Token(84532,weth, 18)

// const poolAddress = Pool.getAddress(
//   config.poolKey.currency0, 
//   config.poolKey.currency1, 
//   config.poolKey.fee
// )
console.log('POOOOOOO1111:')
  let poolId = Pool.getPoolId(tokenLink, weiToken,config.poolKey.fee.toString(),60,ethToken)
  const stateViewContract = await ethers.getContractAt(STATE_VIEW_ABI, STATE_VIEW_ADDRESS);

console.log('POOOOOOO333:', poolId)

let provider = new ethers.providers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/7NsKIcu9tp2GBR_6wuAL3L-oEvo5wflB")
const blockNum = await provider.getBlockNumber()


  // const [slot0, liquidity] = await Promise.all([
  //   stateViewContract.getLiquidity(poolId, {
  //     blockTag: blockNum,
  //   }),
  
   let liquidity = await stateViewContract.getLiquidity(poolId, {
      blockTag: blockNum,
    })
  console.log('Liquidity:', liquidity.toString())


// let rentalityGateway = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

// let contract =  await contractFactory.deploy(poolManager, weth, await rentalityGateway.getAddress())
//   console.log('AccessSenderHook deployed to:', await contract.getAddress())
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
  const v4Planner = new V4Planner()
  const routePlanner = new RoutePlanner()
  
  // Set deadline (1 hour from now)
  const deadline = Math.floor(Date.now() / 1000) + 3600
  
  v4Planner.addAction(Actions.SWAP_EXACT_IN_SINGLE, [config]);
  v4Planner.addAction(Actions.SETTLE_ALL, [config.poolKey.currency0, CurrentConfig.amountIn]);
  v4Planner.addAction(Actions.TAKE_ALL, [config.poolKey.currency1, CurrentConfig.amountOutMinimum]);
  const encodedActions = v4Planner.finalize()
  
  routePlanner.addCommand(CommandType.V4_SWAP, [v4Planner.actions, v4Planner.params])
  

  
  const tx = await universalRouter.execute(
      routePlanner.commands,
      [encodedActions],
      deadline,
      {}
  )
  
  const receipt = await tx.wait()
  console.log('Swap completed! Transaction hash:', receipt.transactionHash)

  console.log(await approvetx.wait())




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
