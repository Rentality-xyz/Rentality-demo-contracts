// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './abstract/IERC20.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityAccessControl.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '../proxy/UUPSAccess.sol';

/// @notice an abstract contract represent available payment types on Rentality.
/// for adding new currency type, smart contract should override 3 main functions
/// getFromUsd, getUsd
abstract contract ARentalityUpgradableCurrencyType is Initializable, UUPSAccess {
  // Current Currency to USD rate and decimals
  int256 internal currentToUsdRate;
  uint8 internal currentToUsdDecimals;

  // Update interval for caching the Currency to USD rate
  uint256 public updateRateInterval;

  // Timestamp of the last update of the Currency to USD rate
  uint256 public lastUpdateRateTimeStamp;

  // Interface for Chainlink Currencty to USD rate feed
  AggregatorV3Interface internal rateFeed;

  // Current token address
  IERC20 public tokenAddress;

  /// @notice Converts the specified amount from USD to the token currency
  /// @dev should be overridden
  /// @param amount The amount in USD cents
  /// @param currencyRate The currency rate to use for conversion
  /// @param decimals The decimals of the token currency
  /// @return The equivalent amount in the token currency
  function getFromUsd(uint256 amount, int256 currencyRate, uint8 decimals) public pure virtual returns (uint256);

  /// @notice Converts the specified amount from the token currency to USD
  /// @dev should be overridden
  /// @param amount The amount in the token currency
  /// @param currencyRate The currency rate to use for conversion
  /// @param decimals The decimals of the token currency
  /// @return The equivalent amount in USD
  function getUsd(uint256 amount, int256 currencyRate, uint8 decimals) public pure virtual returns (uint256);

  /// @notice Retrieves the token address
  /// @return The address of the token contract
  function getTokenAddress() public view virtual returns (address) {
    return address(tokenAddress);
  }

  /// @notice Retrieves the decimals of the token
  /// @return The decimals of the token
  function tokenDecimals() public view returns (uint8) {
    return rateFeed.decimals();
  }

  /// @notice Get the latest rate from the Chainlink rate feed
  /// @return The latest rate
  function getLatest() public view returns (int256) {
    (, int rate, , , ) = rateFeed.latestRoundData();
    return rate;
  }

  /// @notice Retrieves the rate and decimals of the token currency
  /// @return The rate and decimals of the token currency
  function getRate() public view virtual returns (int256, uint8) {
    return (getLatest(), tokenDecimals());
  }

  /// @notice Retrieves the equivalent amount in the token currency from the provided USD value
  /// @param amount The value in USD cents
  /// @return The equivalent amount in the token currency, the corresponding currency rate, and decimals
  function getFromUsdLatest(uint256 amount) public view returns (uint256, int256, uint8) {
    (int256 rate, uint8 decimals) = getRate();

    return (getFromUsd(amount, rate, decimals), rate, decimals);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided token currency amount
  /// @param amount The amount in the token currency
  /// @return The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getUsdFromLatest(uint256 amount) public view returns (uint256, int256, uint8) {
    (int256 rate, uint8 decimals) = getRate();

    return (getUsd(amount, rate, decimals), rate, decimals);
  }

  /// @notice Retrieves the rate and decimals of the token currency with caching
  /// @return The rate and decimals of the token currency
  function getRateWithCache() public returns (int256, uint8) {
    if ((block.timestamp - lastUpdateRateTimeStamp) > updateRateInterval) {
      lastUpdateRateTimeStamp = block.timestamp;
      currentToUsdRate = getLatest();
      currentToUsdDecimals = tokenDecimals();
    }
    return (currentToUsdRate, currentToUsdDecimals);
  }

  /// @notice Retrieves the equivalent amount in the token currency from the provided USD value with caching
  /// @param valueInUsdCents The value in USD cents
  /// @return The equivalent amount in the token currency
  function getFromUsdWithCache(uint256 valueInUsdCents) public returns (uint256) {
    (int256 rate, uint8 decimals) = getRateWithCache();

    return getFromUsd(valueInUsdCents, rate, decimals);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided token currency amount with caching
  /// @param valueInThis The amount in the token currency
  /// @return The equivalent amount in USD cents
  function getUsdWithCache(uint256 valueInThis) public returns (uint256) {
    (int256 rate, uint8 decimals) = getRateWithCache();

    return getUsd(valueInThis, rate, decimals);
  }

  /// @dev Retrieves the cached rate for a given token address.
  /// @return rate The cached rate as an integer.
  /// @return decimals The number of decimal places in the rate.
  function getCurrentRate() public view returns (int, uint8) {
    return (currentToUsdRate, currentToUsdDecimals);
  }
  function setRateFeed(address _rateFeed) public {
    require(userService.isAdmin(msg.sender), "only Admin");
    
    rateFeed = AggregatorV3Interface(_rateFeed);
    (currentToUsdRate, currentToUsdDecimals) = getRate();
  }

  /// @notice Initializes the contract with the specified parameters
  /// @param _userService The address of the Rentality user service contract
  /// @param _tokenAddress The address of the token contract
  /// @param _rateFeed address of chainLink rate feed for corresponding pair
  function initialize(address _userService, address _tokenAddress, address _rateFeed) public virtual initializer {
    userService = IRentalityAccessControl(_userService);
    tokenAddress = IERC20(_tokenAddress);

    if(_rateFeed != address(0)) {
    rateFeed = AggregatorV3Interface(_rateFeed);
    (currentToUsdRate, currentToUsdDecimals) = getRate();
    }
  }
}
