const { ethers } = require("hardhat");

// Uniswap V3 Quoter V2 address (mainnet)
const QUOTER_V2_ADDRESS = "0x61fFE014bA17989E743c5F6cB21bF9697530B21e";

// Uniswap V3 Factory address (mainnet)
const FACTORY_ADDRESS = "0x1F98431c8aD98523631AE4a59f267346ea31F984";

const quoterV2Abi = [
  "function quoteExactInputSingle(tuple(address tokenIn, address tokenOut, uint256 amountIn, uint24 fee, uint160 sqrtPriceLimitX96) params) external returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate)"
];

const factoryAbi = [
  "function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool)"
];

const poolAbi = [
  "function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked)",
  "function liquidity() external view returns (uint128)",
  "function token0() external view returns (address)",
  "function token1() external view returns (address)"
];

async function main() {
  const USDe = "0x4c9edd5852cd905f086c759e8383e09bff1e68b3";
  const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

  // Connect to Quoter V2
  const quoter = await ethers.getContractAt(quoterV2Abi, QUOTER_V2_ADDRESS);
  
  // Connect to Factory
  const factory = await ethers.getContractAt(factoryAbi, FACTORY_ADDRESS);

  // Swap parameters
  const amount = ethers.parseUnits("100000", 18);
  console.log("Amount to swap:", ethers.formatUnits(amount, 18), "USDe");

  // V3 uses fee tiers: 100 (0.01%), 500 (0.05%), 3000 (0.3%), 10000 (1%)
  const fee = 100; // 0.01% fee tier for stablecoins

  // Get pool address
  const poolAddress = await factory.getPool(USDe, USDC, fee);
  console.log("Pool address:", poolAddress);

  if (poolAddress === ethers.ZeroAddress) {
    console.log("Pool does not exist!");
    return;
  }

  // Get pool contract
  const pool = await ethers.getContractAt(poolAbi, poolAddress);

  // Get current pool state
  const slot0 = await pool.slot0();
  const liquidity = await pool.liquidity();
  const token0 = await pool.token0();
  const token1 = await pool.token1();

  console.log("\nPool State:");
  console.log("Token0:", token0);
  console.log("Token1:", token1);
  console.log("Current sqrtPriceX96:", slot0.sqrtPriceX96.toString());
  console.log("Current tick:", slot0.tick.toString());
  console.log("Liquidity:", liquidity.toString());

  // Determine token order
  const zeroForOne = token0.toLowerCase() === USDe.toLowerCase();
  const tokenIn = zeroForOne ? token0 : token1;
  const tokenOut = zeroForOne ? token1 : token0;
  
  console.log("\nSwap Direction:");
  console.log("Zero for One:", zeroForOne);
  console.log("Token In:", tokenIn);
  console.log("Token Out:", tokenOut);

  // Quote the swap
  const params = {
    tokenIn: USDe,
    tokenOut: USDC,
    amountIn: amount,
    fee: fee,
    sqrtPriceLimitX96: 0 // No price limit
  };

  try {
    const result = await quoter.quoteExactInputSingle.staticCall(params);
    
    console.log("\nQuote Result:");
    console.log("Amount Out:", ethers.formatUnits(result.amountOut, 6), "USDC");
    console.log("Price After (sqrtPriceX96):", result.sqrtPriceX96After.toString());
    console.log("Ticks Crossed:", result.initializedTicksCrossed.toString());
    console.log("Gas Estimate:", result.gasEstimate.toString());

    // Calculate current spot price
    const sqrtPriceX96 = Number(slot0.sqrtPriceX96);
    const currentPrice = (sqrtPriceX96 / (2 ** 96)) ** 2;
    
    // Adjust for decimals (USDe has 18 decimals, USDC has 6 decimals)
    const adjustedSpotPrice = currentPrice * (10 ** (18 - 6));
    
    // Calculate effective price from the quote
    const effectivePrice = Number(ethers.formatUnits(result.amountOut, 6)) / 
                          Number(ethers.formatUnits(amount, 18));

    console.log("\nPrice Analysis:");
    console.log("Current spot price:", adjustedSpotPrice.toFixed(10));
    console.log("Effective swap price:", effectivePrice.toFixed(10));

    // Calculate slippage
    const slippagePercent = ((adjustedSpotPrice - effectivePrice) / adjustedSpotPrice) * 100;

    console.log("\nSlippage:", slippagePercent.toFixed(4) + "%");

    // Calculate price impact from sqrtPrice change
    const sqrtPriceAfter = Number(result.sqrtPriceX96After);
    const priceAfter = (sqrtPriceAfter / (2 ** 96)) ** 2;
    const adjustedPriceAfter = priceAfter * (10 ** (18 - 6));
    
    const priceImpact = ((adjustedSpotPrice - adjustedPriceAfter) / adjustedSpotPrice) * 100;
    console.log("Price Impact:", priceImpact.toFixed(4) + "%");

  } catch (error) {
    console.error("Error getting quote:", error.message);
    
    // Try with lower gas limit or check if pool has liquidity
    console.log("\nTroubleshooting:");
    console.log("- Check if the pool has sufficient liquidity");
    console.log("- Try a smaller swap amount");
    console.log("- Verify the fee tier is correct");
  }
}

// Helper function to get pool info for any pair
async function getPoolInfo(token0, token1, fee) {
  const factory = await ethers.getContractAt(factoryAbi, FACTORY_ADDRESS);
  const poolAddress = await factory.getPool(token0, token1, fee);
  
  if (poolAddress === ethers.ZeroAddress) {
    console.log(`No pool found for fee tier ${fee}`);
    return null;
  }

  const pool = await ethers.getContractAt(poolAbi, poolAddress);
  const slot0 = await pool.slot0();
  const liquidity = await pool.liquidity();
  const poolToken0 = await pool.token0();
  const poolToken1 = await pool.token1();

  return {
    address: poolAddress,
    token0: poolToken0,
    token1: poolToken1,
    sqrtPriceX96: slot0.sqrtPriceX96,
    tick: slot0.tick,
    liquidity: liquidity,
    fee: fee
  };
}

// Check all fee tiers for a pair
async function findAllPools(tokenA, tokenB) {
  console.log("\nSearching for pools...");
  const feeTiers = [100, 500, 3000, 10000];
  
  for (const fee of feeTiers) {
    const poolInfo = await getPoolInfo(tokenA, tokenB, fee);
    if (poolInfo) {
      console.log(`\nFound pool with ${fee/10000}% fee:`);
      console.log("Address:", poolInfo.address);
      console.log("Liquidity:", poolInfo.liquidity.toString());
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

module.exports = { getPoolInfo, findAllPools };