const { ethers } = require('hardhat')

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  // Deploy PoolManager
  const PoolManager = await hre.ethers.getContractFactory("PoolManager");
  const poolManager = await PoolManager.deploy();
  await poolManager.waitForDeployment();
  console.log("PoolManager deployed to:", await poolManager.getAddress());



  // const deployer = await ethers.getSigner()
  const contractFactory = await ethers.getContractFactory('AccessSenderHook')
  let linkToken = "0xe4ab69c077896252fafbd49efd26b5d171a32410"
  let amountIn = 25000;
//   let poolManager = "0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408"
  // let usdc = "0x14196f08a4fa0b66b7331bc40dd6bcd8a1deea9f"
  let weth = "0x4200000000000000000000000000000000000006"
  // Prepare pool parameters
  const poolKey = {
    currency0: linkToken,
    currency1: weth,
    fee: 3000, // 0.3% fee
    tickSpacing: 60,
    hooks: "0x0000000000000000000000000000000000000000" // No hooks
  };

  // Calculate sqrtPriceX96 for 1 ETH = 2000 DAI
  const price = 2000;
  const sqrtPrice = Math.sqrt(price);
  const sqrtPriceX96 = BigInt(sqrtPrice * 2 ** 96);

  // Create pool
  const tx = await poolManager.initialize(poolKey, sqrtPriceX96);
  await tx.wait();
  console.log(`Pool created with key: 
    Currency0: ${poolKey.currency0}
    Currency1: ${poolKey.currency1}
    Fee: ${poolKey.fee}
    TickSpacing: ${poolKey.tickSpacing}
    Hooks: ${poolKey.hooks}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});