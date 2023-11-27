// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title RentalityCurrencyConverter
/// @notice A contract for converting between Ether (ETH) and United States Dollar (USD) using Chainlink price feeds
/// @dev Users can retrieve the latest ETH to USD price, convert between ETH and USD, and cache the price for efficiency.
contract RentalityCurrencyConverter {
    // Interface for Chainlink ETH to USD price feed
    AggregatorV3Interface internal ethToUsdPriceFeed;

    // Current ETH to USD price and decimals
    int256 private currentEthToUsdPrice;
    uint8 private currentEthToUsdDecimals;

    // Update interval for caching the ETH to USD price
    uint256 public updatePriceInterval;

    // Timestamp of the last update of the ETH to USD price
    uint256 public lastUpdatePriceTimeStamp;

    /// @param ethToUsdPriceFeedAddress The address of the Chainlink ETH to USD price feed
    constructor(address ethToUsdPriceFeedAddress) {
        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        (currentEthToUsdPrice, currentEthToUsdDecimals) = getEthToUsdPrice();
    }

    /// @notice Get the latest ETH to USD price from the Chainlink price feed
    /// @return The latest ETH to USD price
    function getLatestEthToUsdPrice() private view returns (int256) {
        (, int price, , ,) = ethToUsdPriceFeed.latestRoundData();
        return price;
    }

    /// @notice Get the current ETH to USD price and decimals
    /// @return The current ETH to USD price and decimals
    function getEthToUsdPrice() public view returns (int256, uint8) {
        return (getLatestEthToUsdPrice(), ethToUsdPriceFeed.decimals());
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @return The equivalent amount of ETH, ETH to USD price, and ETH to USD decimals
    function getEthFromUsdLatest(uint256 valueInUsdCents) public view returns (uint256, int256, uint8) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPrice();

        return (
            (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice),
            ethToUsdPrice,
            ethToUsdDecimals
        );
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @return The equivalent amount in USD cents, ETH to USD price, and ETH to USD decimals
    function getUsdFromEthLatest(uint256 valueInEth) public view returns (uint256, int256, uint8) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPrice();

        return (
            ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether))),
            ethToUsdPrice,
            ethToUsdDecimals
        );
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @param ethToUsdPrice The specific ETH to USD price to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return The equivalent amount of ETH
    function getEthFromUsd(uint256 valueInUsdCents, int256 ethToUsdPrice, uint8 ethToUsdDecimals) public pure returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @param ethToUsdPrice The specific ETH to USD price to use for conversion
    /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
    /// @return The equivalent amount in USD cents
    function getUsdFromEth(uint256 valueInEth, int256 ethToUsdPrice, uint8 ethToUsdDecimals) public pure returns (uint256) {
        return ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }

    /// @notice Get the ETH to USD price and decimals with caching
    /// @return The current ETH to USD price and decimals
    function getEthToUsdPriceWithCache() public returns (int256, uint8) {
        if ((block.timestamp - lastUpdatePriceTimeStamp) > updatePriceInterval) {
            lastUpdatePriceTimeStamp = block.timestamp;
            currentEthToUsdPrice = getLatestEthToUsdPrice();
            currentEthToUsdDecimals = ethToUsdPriceFeed.decimals();
        }
        return (currentEthToUsdPrice, currentEthToUsdDecimals);
    }

    /// @notice Get the amount of ETH equivalent to a specified value in USD cents with caching
    /// @param valueInUsdCents The value in USD cents to convert to ETH
    /// @return The equivalent amount of ETH
    function getEthFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPriceWithCache();

        return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdPrice);
    }

    /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
    /// @param valueInEth The amount of ETH to convert to USD cents
    /// @return The equivalent amount in USD cents
    function getUsdFromEthWithCache(uint256 valueInEth) public returns (uint256) {
        (int256 ethToUsdPrice, uint8 ethToUsdDecimals) = getEthToUsdPriceWithCache();

        return ((valueInEth * uint(ethToUsdPrice)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
    }
}
