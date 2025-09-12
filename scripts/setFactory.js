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


 const contract = await ethers.getContractAt('RentalitySwaps', '0xbee52F664e6BF1f4984578c96E1bC3c7655d60D2')
 console.log(await contract.setFactory('0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24'))


}



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
