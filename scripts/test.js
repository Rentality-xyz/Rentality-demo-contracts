const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const { getContractAddress } = require('./utils/contractAddress')
const addressSaver = require('./utils/addressSaver')
const { checkNotNull, startDeploy } = require('./utils/deployHelper')
const { keccak256 } = require('hardhat/internal/util/keccak')
const { zeroHash, ethToken, emptyLocationInfo } = require('../test/utils')

const tripsFilter = {
  paymentStatus: 0,
  status: 0,
  location: emptyLocationInfo,
  startDateTime: 0,
  endDateTime: 1893456000,
}
//block 26718122
async function main() {

  const [deployer] = await ethers.getSigners()
  const contractFactory = await ethers.getContractFactory('RentalitySwaps')
  let linkToken = "0xE4aB69C077896252FAFBD49EFD26B5D171A32410"
  let amountIn = 25000;

  console.log("DD: ",deployer.address)

  // let uniswapFactory = await ethers.getContractAt('UniswapFactory','0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24')
  // let poolCreation = await uniswapFactory.createPool(linkToken,'0x4200000000000000000000000000000000000006', 100);

  // console.log(poolCreation)
  // const contract = await upgrades.deployProxy(contractFactory, ['0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4', '0x4200000000000000000000000000000000000006',linkToken])
  // await contract.waitForDeployment()

  let contract = await ethers.getContractAt('RentalitySwaps', '0x5033F0ECf22bC70710E3a9309BC64B26574913FE')
  let iercContract = await ethers.getContractAt("contracts/payments/abstract/IERC20.sol:IERC20", linkToken)
 let approvetx = await iercContract.approve(await contract.getAddress(), amountIn)

  console.log(await approvetx.wait())


  let args = contract.interface.encodeFunctionData('swapExactInputSingle',[linkToken, amountIn, deployer.address])
  console.log('data:', args)
  let result = await contract.swapExactInputSingle(linkToken, amountIn, deployer.address)
// 
  console.log(result)
  const balance = await ethers.provider.getBalance(await contract.getAddress());
  console.log("BALANCE: ", balance)

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
