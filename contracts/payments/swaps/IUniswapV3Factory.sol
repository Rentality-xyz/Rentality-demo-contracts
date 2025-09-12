   // SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface IUniswapV3Factory { 
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns(address);

     function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}