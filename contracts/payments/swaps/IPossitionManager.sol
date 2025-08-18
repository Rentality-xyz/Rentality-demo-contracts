// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IPoolManager.sol';
interface IPositionManager {
    enum Action { MINT_POSITION, SETTLE_PAIR }
    
    struct ModifyLiquidityParams {
        IPoolManager.PoolKey poolKey;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 amount0Max;
        uint256 amount1Max;
        address recipient;
        bytes hookData;
    }
    
    function multicall(bytes[] calldata data) external payable;
    function modifyLiquidities(bytes calldata actions, bytes[] calldata params) external;
}