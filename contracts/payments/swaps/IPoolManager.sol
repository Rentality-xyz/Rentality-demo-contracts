// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



interface IPoolManager {
 struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}
}