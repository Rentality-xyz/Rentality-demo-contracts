// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IWETH} from './IWETH.sol';
type BalanceDelta is int256;
type PoolId is bytes32;
/// Mimic PoolKey from v4-core
struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}


/// Minimal SwapDelta type
struct SwapDelta {
    uint256 value;
}

/// Mimic Hooks.Permissions
struct Permissions {
    bool beforeInitialize;
    bool afterInitialize;
    bool beforeAddLiquidity;
    bool afterAddLiquidity;
    bool beforeRemoveLiquidity;
    bool afterRemoveLiquidity;
    bool beforeSwap;
    bool afterSwap;
    bool beforeDonate;
    bool afterDonate;
    bool beforeSwapReturnDelta;
    bool afterSwapReturnDelta;
    bool afterAddLiquidityReturnDelta;
    bool afterRemoveLiquidityReturnDelta;
}
/// @notice Parameter struct for `Swap` pool operations
struct SwapParams {
    /// Whether to swap token0 for token1 or vice versa
    bool zeroForOne;
    /// The desired input amount if negative (exactIn), or the desired output amount if positive (exactOut)
    int256 amountSpecified;
    /// The sqrt price at which, if reached, the swap will stop executing
    uint160 sqrtPriceLimitX96;
}

interface IMsgSender {
    function msgSender() external view returns (address);
}

/// Minimal BaseHook mimic
abstract contract BaseHook {
    constructor(address _poolManager) {
        // Initialize with pool manager address
    }
    function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata data) internal virtual returns (bytes4, int128);

        function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external virtual returns (bytes4, int128) {
          return _afterSwap(sender, key, params, delta, hookData);
    }
}

contract AccessSenderHook is BaseHook {
     mapping(PoolId => uint256 count) public afterSwapCount;
     IWETH public weth;

     constructor(address _poolManager, IWETH _weth) BaseHook(_poolManager) {
        weth = _weth;
    }


      function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata data)
        internal
        override
        returns (bytes4, int128)
    {   
        address sender = IMsgSender(msg.sender).msgSender();
        address to = address(bytes20(data[data.length - 20:]));
        uint expectedAmount = abi.decode(data[data.length - 64: 32], (uint));
        bytes memory updatedData = abi.encodePacked(data[data.length - 64:], sender);

        IWETH(weth).withdraw(expectedAmount);
    
        (bool success, bytes memory returnData) = to.call{value: expectedAmount}(updatedData);
        if(!success) {
            revert("Transfer failed");
        }
        afterSwapCount[toId(key)]++;
        return (BaseHook.afterSwap.selector, 0);
    }

    /// @notice Hook permissions
    function getHookPermissions() public pure returns (Permissions memory) {
        return Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,   // disabled
            afterSwap: true,     // enabled
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
   function toId(PoolKey memory poolKey) internal pure returns (PoolId poolId) {
        assembly ("memory-safe") {
            // 0xa0 represents the total size of the poolKey struct (5 slots of 32 bytes)
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}
