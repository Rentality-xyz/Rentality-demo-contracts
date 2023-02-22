// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract MockEthToUsdPriceFeed is MockV3Aggregator {
        
    constructor(uint8 _decimals, int256 _initialAnswer) MockV3Aggregator(_decimals, _initialAnswer) { }
}
