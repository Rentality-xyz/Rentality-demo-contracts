   // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface UniswapFactory { 
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns(address);
}