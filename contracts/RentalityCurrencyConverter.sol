// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './IRentalityAccessControl.sol';
import './proxy/UUPSAccess.sol';

/// @title RentalityCurrencyConverter
/// @notice A contract for converting between Ether (ETH) and United States Dollar (USD) using Chainlink rate feeds
/// @dev Users can retrieve the latest ETH to USD rate, convert between ETH and USD, and cache the rate for efficiency.
contract RentalityCurrencyConverter is Initializable, UUPSAccess {
  // Interface for Chainlink ETH to USD rate feed
  AggregatorV3Interface internal ethToUsdRateFeed;

  // Current ETH to USD rate and decimals
  int256 private currentEthToUsdRate;
  uint8 private currentEthToUsdDecimals;

  // Update interval for caching the ETH to USD rate
  uint256 public updateRateInterval;

  // Timestamp of the last update of the ETH to USD rate
  uint256 public lastUpdateRateTimeStamp;

  /// @notice Get the latest ETH to USD rate from the Chainlink rate feed
  /// @return The latest ETH to USD rate
  function getLatestEthToUsdRate() private view returns (int256) {
    (, int rate, , , ) = ethToUsdRateFeed.latestRoundData();
    return rate;
  }

  /// @notice Get the current ETH to USD rate and decimals
  /// @return ethToUsdRate The ETH to USD rate
  /// @return ethToUsdDecimals The ETH to USD decimals
  function getEthToUsdRate() public view returns (int256 ethToUsdRate, uint8 ethToUsdDecimals) {
    return (getLatestEthToUsdRate(), ethToUsdRateFeed.decimals());
  }

  /// @notice Get the amount of ETH equivalent to a specified value in USD cents
  /// @param valueInUsdCents The value in USD cents to convert to ETH
  /// @return valueInEth The equivalent amount of ETH
  /// @return ethToUsdRate The ETH to USD rate
  /// @return ethToUsdDecimals The ETH to USD decimals
  function getEthFromUsdLatest(uint256 valueInUsdCents) public view returns (uint256 valueInEth, int256 ethToUsdRate, uint8 ethToUsdDecimals) {
    (int256 rate, uint8 decimals) = getEthToUsdRate();

    return (
      (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate),
      rate,
      decimals
    );
  }

  /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
  /// @param valueInEth The amount of ETH to convert to USD cents
  /// @return valueInUsdCents The equivalent amount in USD cents
  /// @return ethToUsdRate The ETH to USD rate
  /// @return ethToUsdDecimals The ETH to USD decimals
  function getUsdFromEthLatest(uint256 valueInEth) public view returns (uint256 valueInUsdCents, int256 ethToUsdRate, uint8 ethToUsdDecimals) {
    (int256 rate, uint8 decimals) = getEthToUsdRate();

    return (
      ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether))),
      rate,
      decimals
    );
  }

  /// @notice Get the amount of ETH equivalent to a specified value in USD cents
  /// @param valueInUsdCents The value in USD cents to convert to ETH
  /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
  /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
  /// @return valueInEth The equivalent amount of ETH
  function getEthFromUsd(
    uint256 valueInUsdCents,
    int256 ethToUsdRate,
    uint8 ethToUsdDecimals
  ) public pure returns (uint256) {
    return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate);
  }

  /// @notice Get the amount of USD cents equivalent to a specified amount of ETH
  /// @param valueInEth The amount of ETH to convert to USD cents
  /// @param ethToUsdRate The specific ETH to USD rate to use for conversion
  /// @param ethToUsdDecimals The specific ETH to USD decimals to use for conversion
  /// @return The equivalent amount in USD cents
  function getUsdFromEth(
    uint256 valueInEth,
    int256 ethToUsdRate,
    uint8 ethToUsdDecimals
  ) public pure returns (uint256) {
    return ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
  }

  /// @notice Get the ETH to USD rate and decimals with caching
  /// @return ethToUsdRate The ETH to USD rate
  /// @return ethToUsdDecimals The ETH to USD decimals
  function getEthToUsdRateWithCache() public returns (int256 ethToUsdRate, uint8 ethToUsdDecimals) {
    if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
      lastUpdateRateTimeStamp = block.timestamp;
      currentEthToUsdRate = getLatestEthToUsdRate();
      currentEthToUsdDecimals = ethToUsdRateFeed.decimals();
    }
    return (currentEthToUsdRate, currentEthToUsdDecimals);
  }

  /// @notice Get the amount of ETH equivalent to a specified value in USD cents with caching
  /// @param valueInUsdCents The value in USD cents to convert to ETH
  /// @return The equivalent amount of ETH
  function getEthFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
    (int256 ethToUsdRate, uint8 ethToUsdDecimals) = getEthToUsdRateWithCache();

    return (valueInUsdCents * (1 ether) * (10 ** (ethToUsdDecimals - 2))) / uint(ethToUsdRate);
  }

  /// @notice Get the amount of USD cents equivalent to a specified amount of ETH with caching
  /// @param valueInEth The amount of ETH to convert to USD cents
  /// @return The equivalent amount in USD cents
  function getUsdFromEthWithCache(uint256 valueInEth) public returns (uint256) {
    (int256 ethToUsdRate, uint8 ethToUsdDecimals) = getEthToUsdRateWithCache();

    return ((valueInEth * uint(ethToUsdRate)) / ((10 ** (ethToUsdDecimals - 2)) * (1 ether)));
  }

  /// @notice contract initialization function
  /// @param _userService address to RentalityUserService
  /// @param ethToUsdRateFeedAddress The address of the Chainlink ETH to USD rate feed
  function initialize(address ethToUsdRateFeedAddress, address _userService) public virtual initializer {
    userService = IRentalityAccessControl(_userService);
    //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
    ethToUsdRateFeed = AggregatorV3Interface(ethToUsdRateFeedAddress);
    (currentEthToUsdRate, currentEthToUsdDecimals) = getEthToUsdRate();
  }
}
