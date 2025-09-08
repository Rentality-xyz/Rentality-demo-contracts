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

let factoryAbi = [
  {
    "inputs": [
      { "internalType": "address", "name": "tokenA", "type": "address" },
      { "internalType": "address", "name": "tokenB", "type": "address" },
      { "internalType": "uint24",  "name": "fee",    "type": "uint24"  }
    ],
    "name": "getPool",
    "outputs": [
      { "internalType": "address", "name": "pool", "type": "address" }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
let poolAbi = [
  {
    "inputs": [
      { "internalType": "uint160", "name": "sqrtPriceX96", "type": "uint160" }
    ],
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]


//block 26718122
async function main() {


  const [deployer] = await ethers.getSigners()

  let linkToken = "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
  let amountIn = 25000;
  let poolManager = "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
  // let usdc = "0x14196f08a4fa0b66b7331bc40dd6bcd8a1deea9f"
  let weth = "0x4200000000000000000000000000000000000006"
  let uniswapFactory = "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24"
  let poolAddress = "0x78c470050f092ff228329C5267FEDA8A03d14d93"
  let nonFingPossitionManager = "0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2"

let config = {
  poolKey: {
      currency0: weth,
      currency1: linkToken,
      fee: 3000,
      tickSpacing: 60,
      hooks: ethToken,
  },
  zeroForOne: false,
  amountIn: amountIn, 
  amountOutMinimum: 0,
  hookData: '0x000'
}

const positionManager = await ethers.getContractAt([
  "function mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256)) returns (uint256,uint128,uint256,uint256)"
], nonFingPossitionManager);

const params = [
  weth, // token0
  linkToken, // token1
  3000, // fee
  -887220, // tickLower
  887220,  // tickUpper
  ethers.parseUnits("1.0", 18), // amount0Desired
  ethers.parseUnits("1.0", 18), // amount1Desired
  0, // amount0Min
  0, // amount1Min
  deployer.address, // recipient
  Math.floor(Date.now() / 1000) + 60 * 10 // deadline
];
// let linkContract = await ethers.getContractAt('contracts/payments/abstract/IERC20.sol:IERC20',linkToken)
// let wethContract = await ethers.getContractAt('contracts/payments/abstract/IERC20.sol:IERC20',weth)
// console.log(linkContract)
// await linkContract.approve(nonFingPossitionManager, ethers.parseUnits("1.0", 18));
// await wethContract.approve(nonFingPossitionManager,  ethers.parseUnits("1.0", 18));

console.log("HERE")
// const tx = await positionManager.mint(params);
// const receipt = await tx.wait();
// console.log(tx)

const v3Pool = await ethers.getContractAt(
  [
    "function liquidity() view returns (uint128)",
    "function slot0() view returns (uint160,int24,uint16,uint16,uint16,uint8,bool)"
  ],
  poolAddress
);
const L = await v3Pool.liquidity();
console.log("LIQUDITY: ",L)

const contractFactory = await ethers.getContractFactory('RentalitySwaps')
let swapContract = await ethers.getContractAt('RentalitySwaps', '0xb4Bb19B98159C2E1Dd1764Cf1F7f743e4efc0373')
// let swapContract =  await upgrades.deployProxy(contractFactory,["0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4", weth, linkToken, ethToken])
  // console.log('SWAP ROUTER deployed to:', await swapContract.getAddress())

// let factory = await ethers.getContractAt(factoryAbi, uniswapFactory);
// let pool = await factory.getPool(weth, linkToken,3000)
// console.log("pool: ", pool)

// let pool = await ethers.getContractAt(poolAbi, poolAddress)
// console.log(await pool.initialize(BigInt("79228162514264337593543950336")))
 
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


  let poolId = ethers.keccak256(encoded)
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

// let approveTx = await swapContract.approveTokenWithPermit2(
//   linkToken,
//   amountIn + 10,
//   expiration
// )

let ierc20 = await ethers.getContractAt('contracts/payments/abstract/IERC20.sol:IERC20', linkToken)
// let approveTx = await ierc20.approve(await swapContract.getAddress(), amountIn)
// console.log('Approve transaction hash:', approveTx.hash)

let data = rentalityGateway.interface.encodeFunctionData('payKycCommission', [ethToken])

// let key =   {
//   currency0: linkToken,
//   currency1: weth,
//   fee: 3000,
//   tickSpacing: 60,
//   hooks: ethToken,
// }
let encodedData = swapContract.interface.encodeFunctionData(
  'swapExactInputSingle',
  [
    linkToken,
    config.amountIn,
    deployer.address
  ]
)
console.log('Encoded data:', encodedData)

let swapTx = await swapContract.swapExactInputSingle(
  linkToken,
  config.amountIn,
  deployer.address
)

console.log('Swap transaction hash:', swapTx.hash)


}



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })


