const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades, network } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')
// const { Actions, V4Planner } = require('@uniswap/v4-sdk')
//   const { CommandType, RoutePlanner } = require('@uniswap/universal-router-sdk')
const { deploy } = require('@openzeppelin/hardhat-upgrades/dist/utils')
const { config } = require('dotenv')
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
  let linkToken = "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
  let amountIn = 25000;
  let poolManager = "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
  // let usdc = "0x14196f08a4fa0b66b7331bc40dd6bcd8a1deea9f"
  let weth = "0x4200000000000000000000000000000000000006"

let config = {
  poolKey: {
      currency0: weth.trim(),
      currency1: linkToken.trim(),
      fee: 3000,
      tickSpacing: 60,
      hooks: ethToken,
  },
  zeroForOne: true,
  amountIn: amountIn, 
  amountOutMinimum: 0,
  hookData: '0x000'
}

let swapContract = await ethers.getContractAt('IRentalitySwap', '0x7f4947155E1f0Fb6798165c1356fA92A6F3aD1fB')
  const stateViewContract = await ethers.getContractAt(STATE_VIEW_ABI, STATE_VIEW_ADDRESS);

  const abiCoder = new ethers.AbiCoder();
  const encoded = abiCoder.encode(
    ["address","address","uint24","int24","address"],
    [
      config.poolKey.currency0,
      config.poolKey.currency1,
      config.poolKey.fee,
      config.poolKey.tickSpacing,
      config.poolKey.hooks
    ]
  );
  console.log('Encoded pool key:', encoded)


  let poolId = ethers.keccak256(encoded)
  console.log('Pool ID:', poolId)
  // 0x525bbcb70b04a9aa87db2f54626100b6156963b9b2f1b264db73846c737f851f
  // let poolId = poolKeyToId(config.poolKey)

  // // const [slot0, liquidity] = await Promise.all([
  // //   stateViewContract.getLiquidity(poolId, {
  // //     blockTag: blockNum,
  // //   }),

  let provider = new ethers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/7NsKIcu9tp2GBR_6wuAL3L-oEvo5wflB")
  let blockNum = await provider.getBlockNumber()
  
   let liquidity = await stateViewContract.getLiquidity(poolId,{
    blockTag: blockNum,
   })


let rentalityGateway = await ethers.getContractAt('IRentalityGateway','0xB257FE9D206b60882691a24d5dfF8Aa24929cB73')

// let contract =  await contractFactory.deploy(poolManager, weth, await rentalityGateway.getAddress())
//   console.log('AccessSenderHook deployed to:', await contract.getAddress())
let expiration = Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30


let approveTx = await swapContract.approveTokenWithPermit2(
  linkToken,
  amountIn,
  expiration
)

console.log('Approve transaction hash:', approveTx.hash)

let data = rentalityGateway.interface.encodeFunctionData('payKycCommission', [ethToken])

// let key =   {
//   currency0: linkToken,
//   currency1: weth,
//   fee: 3000,
//   tickSpacing: 60,
//   hooks: ethToken,
// }
// let encodedData = swapContract.interface.encodeFunctionData(
//   'swapExactInputSingle',
//   [
//     config.poolKey,
//     config.amountIn,
//     0,
//     data
//   ]
// )
// console.log('Encoded data:', encodedData)

let swapTx = await swapContract.swapExactInputSingle(
  config.poolKey,
  config.amountIn,
  0,
  data
)


console.log('Swap transaction hash:', swapTx.hash)


}



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })


