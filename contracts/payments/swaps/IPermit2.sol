// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



interface IPermit2 {
function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
}