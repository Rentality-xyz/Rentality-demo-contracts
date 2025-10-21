const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy, checkNotNull } = require('./utils/deployHelper')
const { getContractAddress } = require('./utils/contractAddress')
const { zeroHash, ethToken } = require('../test/utils')

const quoterAbi = [
    {
        "inputs": [
            {
                "internalType": "contract IPoolManager",
                "name": "_poolManager",
                "type": "address"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            {
                "internalType": "PoolId",
                "name": "poolId",
                "type": "bytes32"
            }
        ],
        "name": "NotEnoughLiquidity",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "NotPoolManager",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "NotSelf",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "QuoteSwap",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "UnexpectedCallSuccess",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "revertData",
                "type": "bytes"
            }
        ],
        "name": "UnexpectedRevertBytes",
        "type": "error"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "internalType": "Currency",
                        "name": "exactCurrency",
                        "type": "address"
                    },
                    {
                        "components": [
                            {
                                "internalType": "Currency",
                                "name": "intermediateCurrency",
                                "type": "address"
                            },
                            {
                                "internalType": "uint24",
                                "name": "fee",
                                "type": "uint24"
                            },
                            {
                                "internalType": "int24",
                                "name": "tickSpacing",
                                "type": "int24"
                            },
                            {
                                "internalType": "contract IHooks",
                                "name": "hooks",
                                "type": "address"
                            },
                            {
                                "internalType": "bytes",
                                "name": "hookData",
                                "type": "bytes"
                            }
                        ],
                        "internalType": "struct PathKey[]",
                        "name": "path",
                        "type": "tuple[]"
                    },
                    {
                        "internalType": "uint128",
                        "name": "exactAmount",
                        "type": "uint128"
                    }
                ],
                "internalType": "struct IV4Quoter.QuoteExactParams",
                "name": "params",
                "type": "tuple"
            }
        ],
        "name": "quoteExactInput",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "amountOut",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "gasEstimate",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "components": [
                            {
                                "internalType": "Currency",
                                "name": "currency0",
                                "type": "address"
                            },
                            {
                                "internalType": "Currency",
                                "name": "currency1",
                                "type": "address"
                            },
                            {
                                "internalType": "uint24",
                                "name": "fee",
                                "type": "uint24"
                            },
                            {
                                "internalType": "int24",
                                "name": "tickSpacing",
                                "type": "int24"
                            },
                            {
                                "internalType": "contract IHooks",
                                "name": "hooks",
                                "type": "address"
                            }
                        ],
                        "internalType": "struct PoolKey",
                        "name": "poolKey",
                        "type": "tuple"
                    },
                    {
                        "internalType": "bool",
                        "name": "zeroForOne",
                        "type": "bool"
                    },
                    {
                        "internalType": "uint128",
                        "name": "exactAmount",
                        "type": "uint128"
                    },
                    {
                        "internalType": "bytes",
                        "name": "hookData",
                        "type": "bytes"
                    }
                ],
                "internalType": "struct IV4Quoter.QuoteExactSingleParams",
                "name": "params",
                "type": "tuple"
            }
        ],
        "name": "quoteExactInputSingle",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "amountOut",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "gasEstimate",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "internalType": "Currency",
                        "name": "exactCurrency",
                        "type": "address"
                    },
                    {
                        "components": [
                            {
                                "internalType": "Currency",
                                "name": "intermediateCurrency",
                                "type": "address"
                            },
                            {
                                "internalType": "uint24",
                                "name": "fee",
                                "type": "uint24"
                            },
                            {
                                "internalType": "int24",
                                "name": "tickSpacing",
                                "type": "int24"
                            },
                            {
                                "internalType": "contract IHooks",
                                "name": "hooks",
                                "type": "address"
                            },
                            {
                                "internalType": "bytes",
                                "name": "hookData",
                                "type": "bytes"
                            }
                        ],
                        "internalType": "struct PathKey[]",
                        "name": "path",
                        "type": "tuple[]"
                    },
                    {
                        "internalType": "uint128",
                        "name": "exactAmount",
                        "type": "uint128"
                    }
                ],
                "internalType": "struct IV4Quoter.QuoteExactParams",
                "name": "params",
                "type": "tuple"
            }
        ],
        "name": "quoteExactOutput",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "amountIn",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "gasEstimate",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "components": [
                            {
                                "internalType": "address",
                                "name": "currency0",
                                "type": "address"
                            },
                            {
                                "internalType": "address",
                                "name": "currency1",
                                "type": "address"
                            },
                            {
                                "internalType": "uint24",
                                "name": "fee",
                                "type": "uint24"
                            },
                            {
                                "internalType": "int24",
                                "name": "tickSpacing",
                                "type": "int24"
                            },
                            {
                                "internalType": "contract IHooks",
                                "name": "hooks",
                                "type": "address"
                            }
                        ],
                        "internalType": "struct PoolKey",
                        "name": "poolKey",
                        "type": "tuple"
                    },
                    {
                        "internalType": "bool",
                        "name": "zeroForOne",
                        "type": "bool"
                    },
                    {
                        "internalType": "uint128",
                        "name": "exactAmount",
                        "type": "uint128"
                    },
                    {
                        "internalType": "bytes",
                        "name": "hookData",
                        "type": "bytes"
                    }
                ],
                "internalType": "struct IV4Quoter.QuoteExactSingleParams",
                "name": "params",
                "type": "tuple"
            }
        ],
        "name": "quoteExactOutputSingle",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "amountIn",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "gasEstimate",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "unlockCallback",
        "outputs": [
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
const POOL_MANAGER_ADDRESS = "0x000000000004444c5dc75cB358380D2e3dE08A90"

async function main() {
    
    const USDe = "0x4c9edd5852cd905f086c759e8383e09bff1e68b3";
    const USDC = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
    const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

 
  let swaps = await ethers.getContractAt(quoterAbi, '0x52f0e24d1c21c8a0cb1e5a5dd6198556bd9e1203')
//   Fee (bps)	Typical tick spacing
//   100	1
//   500	10
//   3000	60
//   10000	200
// 100к
const amount = ethers.parseUnits("100000",18)
console.log("AMOUnT: ", amount)
const poolKey = {
    currency0: USDe,
    currency1: USDT,
    fee: 63, 
    tickSpacing: 1,
    hooks: "0x0000000000000000000000000000000000000000" 
};

const params = {
    poolKey: poolKey,
    zeroForOne: true,
    exactAmount: amount,
    hookData: "0x" // Empty bytes
};


const encodedData = swaps.interface.encodeFunctionData("quoteExactInputSingle", [params]);

console.log("Fn params: ", encodedData)
const result = await swaps.quoteExactInputSingle.staticCall(params,
     {
        gasLimit: 5000000 // Example: increase to 5,000,000 gas units
      });
    
//     , {
//     gasLimit: 8_000_000, 
//   }))

console.log("RESULT: ", result)

const poolContract = await getPoolAddressWithSDK(poolKey)
console.log(poolContract)

const currentPoint = '-276318'; 
const sqrtPriceX96 = '79234108437319948577588'; 
let price = (sqrtPriceX96 / 2 ** 96) ** 2;


const adjustedSpotPrice = price * (10 ** (18 - 6));
console.log("Price before swap: ", adjustedSpotPrice)
const priceAfterSwap = (Number(result.amountOut) / 10**6) / (Number(amount) / 10**18);
console.log("Price after swap: ", priceAfterSwap)

// Effective price from your swap
const effectivePrice = Number(ethers.formatUnits(result.amountOut, 6)) / Number(ethers.formatUnits(amount, 18));


console.log("Current spot price:", adjustedSpotPrice);
console.log("Effective swap price:", effectivePrice);

const slippagePercent = ((adjustedSpotPrice - effectivePrice) / adjustedSpotPrice) * 100;

console.log("Slippage (%):", slippagePercent.toFixed(4));
// const expectedPrice = Number(ethers.formatUnits(result.amountOut, 6)) / Number(ethers.formatUnits(amount, 18));

// const slippagePercent = (1 - expectedPrice / price) * 100;

// console.log("Expected slippage (%):", slippagePercent.toFixed(4));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })


  async function getPoolAddressWithSDK(poolKey) {
    // If using @uniswap/v4-sdk
    // import { Pool } from '@uniswap/v4-sdk';
    // const pool = new Pool(poolKey);
    // return pool.poolId;
    
    // Or interact with PoolManager contract
    const poolManagerAbi = [
        "function getPool(bytes32 id) external view returns (address)",
    "function extsload(bytes32 slot) external view returns (bytes32)"
    ];
    
    const poolManager =  await ethers.getContractAt(
        poolManagerAbi,
        POOL_MANAGER_ADDRESS
    );
    
    // const poolId = getPoolId('');
    // console.log("POOL ID: ", poolId)
    
    // Check if pool exists
    const poolState = await poolManager.extsload('0x719ab2d9c9836a5851b88bb987cabdce4d8b1704dd04eeb2b819094d3d8ace2c');
    
    console.log("POOL STATE", poolState)
    // return {
    //     poolId: poolId,
    //     sqrtPriceX96: poolState.sqrtPriceX96.toString(),
    //     tick: poolState.tick,
    //     exists: poolState.sqrtPriceX96 > 0
    // };
}

function getPoolId(poolKey) {
    // Encode the pool key struct
    const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'address', 'uint24', 'int24', 'address'],
        [
            poolKey.currency0,
            poolKey.currency1,
            poolKey.fee,
            poolKey.tickSpacing,
            poolKey.hooks
        ]
    );
    
    // Hash to get pool ID
    return ethers.keccak256(encoded);
}
