// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

interface IRentalitySwap {

  function approveTokenWithPermit2(
	address token,
	uint160 amount,
	uint48 expiration
) external;

function swapExactInputSingle(
    PoolKey calldata key,
    bool toToken0,
    uint128 amountIn,
    uint128 minAmountOut,
    bytes calldata hookData
) external returns (uint256 amountOut);
}