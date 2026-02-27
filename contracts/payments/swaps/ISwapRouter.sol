// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



     struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
interface ISwapRouter {

 
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}