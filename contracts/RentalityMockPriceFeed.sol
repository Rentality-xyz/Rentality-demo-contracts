// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

/// @title Rentality Mock Price Feed Contract
/// @notice This contract represents a mock Chainlink price feed for testing purposes.
/// @dev It extends the MockV3Aggregator and allows configuring the number of decimals and initial answer.
contract RentalityMockPriceFeed is MockV3Aggregator {

    /// @notice Constructor to initialize the mock price feed.
    /// @param _decimals The number of decimals for the price feed.
    /// @param _initialAnswer The initial answer (price) for the price feed.
    constructor(uint8 _decimals, int256 _initialAnswer) MockV3Aggregator(_decimals, _initialAnswer) { }
}
