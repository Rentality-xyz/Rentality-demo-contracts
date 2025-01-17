// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//deployed 26.05.2023 11:15 to sepolia at 0x3E69da2133f87a3CC2602b351869046C2D8Aef2A

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityAccessControl.sol';
import '../proxy/UUPSAccess.sol';
import '../Schemas.sol';
import './RentalityCurrencyType.sol';
import {RentalityPromoService} from '../features/RentalityPromo.sol';

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
  /// @param tokenAddress The address of the currency type to convert to
  /// @param amount The amount in USD cents to convert
  /// @param currencyRate The currency rate to use for conversion
  /// @param decimals The decimals of the currency type
  /// @return The equivalent amount in the specified currency type
  function getFromUsd(
    address tokenAddress,
    uint256 amount,
    int256 currencyRate,
    uint8 decimals
  ) public view returns (uint) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsd(amount, currencyRate, decimals);
  }

  /// @notice Retrieves the latest rate of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return The latest rate of the currency type
  function getLatest(address tokenAddress) public view returns (int) {
    return tokenAddressToPaymentMethod[tokenAddress].getLatest();
  }

  /// @notice Retrieves the rate and decimals of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return The rate and decimals of the currency type
  function getRate(address tokenAddress) public view returns (int256, uint8) {
    return tokenAddressToPaymentMethod[tokenAddress].getRate();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return The equivalent amount in the specified currency type, the corresponding currency rate, and decimals
  function getFromUsdLatest(
    address tokenAddress,
    uint256 valueInUsdCents
  ) public view returns (uint256, int256, uint8) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsdLatest(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getToUsdLatest(address tokenAddress, uint256 amount) public view returns (uint256, int256, uint8) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsdFromLatest(amount);
  }

  /// @notice Converts the specified amount from the specified currency type to USD
  /// @param tokenAddress The address of the currency type
  /// @param tokenValue The amount in the specified currency type
  /// @param tokenToUsd The currency rate from the specified currency type to USD
  /// @param decimals The decimals of the currency type
  /// @return The equivalent amount in USD
  function getToUsd(
    address tokenAddress,
    uint256 tokenValue,
    int256 tokenToUsd,
    uint8 decimals
  ) public view returns (uint256) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsd(tokenValue, tokenToUsd, decimals);
  }

  /// @notice Retrieves the currency rate and decimals of the specified currency type with cache
  /// @param tokenAddress The address of the currency type
  /// @return The currency rate and decimals of the currency type
  function getCurrencyRateWithCache(address tokenAddress) public returns (int256, uint8) {
    return tokenAddressToPaymentMethod[tokenAddress].getRateWithCache();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value with cache
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return The equivalent amount in the specified currency type
  function getFromUsdWithCache(address tokenAddress, uint256 valueInUsdCents) public returns (uint256) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsdWithCache(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount with cache
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return The equivalent amount in USD cents
  function getToUsdWithCache(address tokenAddress, uint256 amount) public returns (uint256) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsdWithCache(amount);
  }

  /// @dev Retrieves the cached rate for a given token address.
  /// @param tokenAddress The address of the token for which to retrieve the rate.
  /// @return rate The cached rate as an integer.
  /// @return decimals The number of decimal places in the rate.
  function getCurrentRate(address tokenAddress) public view returns (int, uint8) {
    return tokenAddressToPaymentMethod[tokenAddress].getCurrentRate();
  }

  /// @notice Checks if the specified currency type is available
  /// @param tokenAddress The address of the currency type
  /// @return A boolean indicating if the currency type is available
  function currencyTypeIsAvailable(address tokenAddress) public view returns (bool) {
    return address(tokenAddressToPaymentMethod[tokenAddress]) != address(0);
  }

  function calculateLatestValueWithFee(
    address tokenAddress,
    uint value,
    uint commission
  ) public view returns (uint, uint, int, uint8) {
    (uint256 valueToPay, int256 rate, uint8 dec) = getFromUsdLatest(tokenAddress, value + commission);

    uint256 feeInCurrency = getFromUsd(tokenAddress, commission, rate, dec);
    return (valueToPay, feeInCurrency, rate, dec);
  }

  function calculateTripFinsish(
    Schemas.PaymentInfo memory paymentInfo,
    uint256 rentalityFee,
    uint insurancePriceInUsdCents,
    RentalityPromoService promoService
  ) public view returns (uint, uint, uint, uint, uint) {
    uint discount = promoService.getPromoDiscountByTrip(paymentInfo.tripId);


    uint256 valueToHostInUsdCents = paymentInfo.priceWithDiscount +
      paymentInfo.pickUpFee +
      paymentInfo.dropOfFee +
      paymentInfo.resolveAmountInUsdCents -
      rentalityFee +
      insurancePriceInUsdCents;

    uint256 valueToGuestInUsdCents = paymentInfo.depositInUsdCents - paymentInfo.resolveAmountInUsdCents;

    uint256 valueToHost = getFromUsd(
      paymentInfo.currencyType,
      valueToHostInUsdCents,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    );
    uint256 valueToGuest = getFromUsd(
      paymentInfo.currencyType,
      valueToGuestInUsdCents,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    );
    uint256 totalIncome = getFromUsd(
      paymentInfo.currencyType,
      valueToHostInUsdCents - paymentInfo.resolveAmountInUsdCents + rentalityFee,
      paymentInfo.currencyRate,
      paymentInfo.currencyDecimals
    );
      if(discount == 100) {
          valueToGuest = 0;
          valueToGuestInUsdCents = 0;
      }
    return (valueToHost, valueToGuest, valueToHostInUsdCents, valueToGuestInUsdCents, totalIncome);
  }

  function calculateTripReject(Schemas.PaymentInfo memory paymentInfo, uint insurance) public pure returns (uint) {
    uint64 valueToReturnInUsdCents = paymentInfo.priceWithDiscount +
      paymentInfo.salesTax +
      paymentInfo.governmentTax +
      uint64(paymentInfo.pickUpFee) +
      uint64(paymentInfo.dropOfFee) +
      paymentInfo.depositInUsdCents +
      uint64(insurance);

    return valueToReturnInUsdCents;
  }

  /// @notice Checks if the specified currency type is native
  /// @param tokenAddress The address of the currency type
  /// @return A boolean indicating if the currency type is native
  function isETH(address tokenAddress) public pure returns (bool) {
    return tokenAddress == address(0);
  }

  /// @notice Initializes the contract with the specified parameters
  /// @param _userService The address of the Rentality user service contract
  /// @param ethPaymentAddress The address of the ETH payment contract
  function initialize(address _userService, address ethPaymentAddress) public virtual initializer {
    tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethPaymentAddress);
    userService = IRentalityAccessControl(_userService);
  }
}
