// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityAccessControl.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import './RentalityCurrencyType.sol';

/// @title RentalityCurrencygeter
/// @notice A contract for getting between available on Rentality currency and United States Dollar (USD) using Chainlink rate feeds
/// @dev Users can retrieve the latest Currency to USD rate, and cache the rate for efficiency.
contract RentalityCurrencyConverter is Initializable, UUPSAccess {
  mapping(address => ARentalityUpgradableCurrencyType) private tokenAddressToPaymentMethod;

  /// @notice Adds a new currency type with its associated Rentality token service contract address
  /// @param tokenAddress The address of the new currency type
  /// @param rentalityTokenService The address of the Rentality token service contract
  function addCurrencyType(address tokenAddress, address rentalityTokenService) public {
    require(userService.isManager(msg.sender), 'From manager contract only.');

    tokenAddressToPaymentMethod[tokenAddress] = ARentalityUpgradableCurrencyType(rentalityTokenService);
  }

  /// @notice Converts the specified amount from USD to the specified currency type
  /// @param currencyType The address of the currency type to convert to
  /// @param amount The amount in USD cents to convert
  /// @param currencyRate The currency rate to use for conversion
  /// @param decimals The decimals of the currency type
  /// @return The equivalent amount in the specified currency type
  function getFromUsd(
    address currencyType,
    uint256 amount,
    int256 currencyRate,
    uint8 decimals
  ) public view returns (uint) {
    return tokenAddressToPaymentMethod[currencyType].getFromUsd(amount, currencyRate, decimals);
  }

  /// @notice Retrieves the latest rate of the specified currency type
  /// @param currencyType The address of the currency type
  /// @return The latest rate of the currency type
  function getLatest(address currencyType) public view returns (int) {
    return tokenAddressToPaymentMethod[currencyType].getLatest();
  }

  /// @notice Retrieves the rate and decimals of the specified currency type
  /// @param currencyType The address of the currency type
  /// @return The rate and decimals of the currency type
  function getRate(address currencyType) public view returns (int256, uint8) {
    return tokenAddressToPaymentMethod[currencyType].getRate();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value
  /// @param currencyType The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return The equivalent amount in the specified currency type, the corresponding currency rate, and decimals
  function getFromUsdLatest(
    address currencyType,
    uint256 valueInUsdCents
  ) public view returns (uint256, int256, uint8) {
    return tokenAddressToPaymentMethod[currencyType].getFromUsdLatest(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount
  /// @param currencyType The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getToUsdLatest(address currencyType, uint256 amount) public view returns (uint256, int256, uint8) {
    return tokenAddressToPaymentMethod[currencyType].getUsdFromLatest(amount);
  }

  /// @notice Converts the specified amount from the specified currency type to USD
  /// @param currencyType The address of the currency type
  /// @param tokenValue The amount in the specified currency type
  /// @param tokenToUsd The currency rate from the specified currency type to USD
  /// @param decimals The decimals of the currency type
  /// @return The equivalent amount in USD
  function getToUsd(
    address currencyType,
    uint256 tokenValue,
    int256 tokenToUsd,
    uint8 decimals
  ) public view returns (uint256) {
    return tokenAddressToPaymentMethod[currencyType].getUsd(tokenValue, tokenToUsd, decimals);
  }

  /// @notice Retrieves the currency rate and decimals of the specified currency type with cache
  /// @param currencyType The address of the currency type
  /// @return The currency rate and decimals of the currency type
  function getCurrencyRateWithCache(address currencyType) public returns (int256, uint8) {
    return tokenAddressToPaymentMethod[currencyType].getRateWithCache();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value with cache
  /// @param currencyType The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return The equivalent amount in the specified currency type
  function getFromUsdWithCache(address currencyType, uint256 valueInUsdCents) public returns (uint256) {
    return tokenAddressToPaymentMethod[currencyType].getFromUsdWithCache(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount with cache
  /// @param currencyType The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return The equivalent amount in USD cents
  function getToUsdWithCache(address currencyType, uint256 amount) public returns (uint256) {
    return tokenAddressToPaymentMethod[currencyType].getUsdWithCache(amount);
  }

  /// @notice Checks if the specified currency type is available
  /// @param currencyType The address of the currency type
  /// @return A boolean indicating if the currency type is available
  function currencyTypeIsAvailable(address currencyType) public view returns (bool) {
    return address(tokenAddressToPaymentMethod[currencyType]) != address(0);
  }

  /// @notice Checks if the specified currency type is native
  /// @param currencyType The address of the currency type
  /// @return A boolean indicating if the currency type is native
  function isNative(address currencyType) public pure returns (bool) {
    return currencyType == address(0);
  }

  /// @notice Initializes the contract with the specified parameters
  /// @param _userService The address of the Rentality user service contract
  /// @param ethPaymentAddress The address of the ETH payment contract
  function initialize(address _userService, address ethPaymentAddress) public virtual initializer {
    tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethPaymentAddress);
    userService = IRentalityAccessControl(_userService);
  }
}
