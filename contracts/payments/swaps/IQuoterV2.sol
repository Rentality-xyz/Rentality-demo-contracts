// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IQuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    struct QuoteExactInputParams {
        bytes path;
        uint256 amountIn;
    }

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountOut;
        uint160 sqrtPriceLimitX96;
    }

    struct QuoteExactOutputParams {
        bytes path;
        uint256 amountOut;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams calldata params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    function quoteExactInput(QuoteExactInputParams calldata params)
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    function quoteExactOutputSingle(QuoteExactOutputSingleParams calldata params)
        external
        view
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    function quoteExactOutput(QuoteExactOutputParams calldata params)
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );
}
