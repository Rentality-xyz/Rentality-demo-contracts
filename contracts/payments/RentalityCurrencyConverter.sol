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

  Schemas.Currency[] private availableCurrencies;

  mapping(address =>  Schemas.UserCurrency) private userToCurrency;
  Schemas.UserCurrency private defaultCurrency;

  function addUserCurrency(address user, address currency) public {
    require(userService.isRentalityPlatform(msg.sender), 'From platform contract only.');
    require(address(tokenAddressToPaymentMethod[currency]) != address(0), 'Currency not available.');
    userToCurrency[user] =  Schemas.UserCurrency(currency, true);
  }
  function getUserCurrency(address user) public view returns ( Schemas.UserCurrency memory currency) {
      Schemas.UserCurrency memory userCurrency = userToCurrency[user];
     if(userCurrency.initialized) {
       return userCurrency;
     }
     return defaultCurrency;
  }

  function setDefaultCurrencyType(address currency) public {
    require(userService.isAdmin(tx.origin), 'only for Admin');
    require(address(tokenAddressToPaymentMethod[currency]) != address(0), 'Currency not available.');
    defaultCurrency =  Schemas.UserCurrency(currency, false);
  }

  /// @notice Adds a new currency type with its associated Rentality token service contract address
  /// @param tokenAddress The address of the new currency type
  /// @param rentalityTokenService The address of the Rentality token service contract
  function addCurrencyType(address tokenAddress, address rentalityTokenService, string memory name) public {
    require(userService.isRentalityPlatform(msg.sender), 'From manager contract only.');

    tokenAddressToPaymentMethod[tokenAddress] = ARentalityUpgradableCurrencyType(rentalityTokenService);
    availableCurrencies.push(Schemas.Currency(tokenAddress, name));
  }

  /// @notice Converts the specified amount from USD to the specified currency type
  /// @param tokenAddress The address of the currency type to convert to
  /// @param amount The amount in USD cents to convert
  /// @param currencyRate The currency rate to use for conversion
  /// @param decimals The decimals of the currency type
  /// @return amountInCurrency The equivalent amount in the specified currency type
  function getFromUsd(
    address tokenAddress,
    uint256 amount,
    int256 currencyRate,
    uint8 decimals
  ) public view returns (uint amountInCurrency) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsd(amount, currencyRate, decimals);
  }

  /// @notice Retrieves the latest rate of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return latestRate The latest rate of the currency type
  function getLatest(address tokenAddress) public view returns (int latestRate) {
    return tokenAddressToPaymentMethod[tokenAddress].getLatest();
  }

  /// @notice Retrieves the rate and decimals of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return rate The rate and decimals of the currency type
  function getRate(address tokenAddress) public view returns (int256 rate, uint8 decimals) {
    return tokenAddressToPaymentMethod[tokenAddress].getRate();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return valueInCurrency The equivalent amount in the specified currency type, the corresponding currency rate, and decimals
  function getFromUsdLatest(
    address tokenAddress,
    uint256 valueInUsdCents
  ) public view returns (uint256 valueInCurrency, int256 rate, uint8 decimals) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsdLatest(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return usdLatest The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getToUsdLatest(
    address tokenAddress,
    uint256 amount
  ) public view returns (uint256 usdLatest, int256 rate, uint8 decimals) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsdFromLatest(amount);
  }

  /// @notice Converts the specified amount from the specified currency type to USD
  /// @param tokenAddress The address of the currency type
  /// @param tokenValue The amount in the specified currency type
  /// @param tokenToUsd The currency rate from the specified currency type to USD
  /// @param decimals The decimals of the currency type
  /// @return valueInUsd The equivalent amount in USD
  function getToUsd(
    address tokenAddress,
    uint256 tokenValue,
    int256 tokenToUsd,
    uint8 decimals
  ) public view returns (uint256 valueInUsd) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsd(tokenValue, tokenToUsd, decimals);
  }

  /// @notice Retrieves the currency rate and decimals of the specified currency type with cache
  /// @param tokenAddress The address of the currency type
  /// @return cachedRate The currency rate of the currency type
  /// @return decimals The currency decimals of the currency type
  function getCurrencyRateWithCache(address tokenAddress) public returns (int256 cachedRate, uint8 decimals) {
    return tokenAddressToPaymentMethod[tokenAddress].getRateWithCache();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value with cache
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return cachedValueInCurrency The equivalent amount in the specified currency type
  function getFromUsdWithCache(
    address tokenAddress,
    uint256 valueInUsdCents
  ) public returns (uint256 cachedValueInCurrency) {
    return tokenAddressToPaymentMethod[tokenAddress].getFromUsdWithCache(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount with cache
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return cachedValueInUsd The equivalent amount in USD cents
  function getToUsdWithCache(address tokenAddress, uint256 amount) public returns (uint256 cachedValueInUsd) {
    return tokenAddressToPaymentMethod[tokenAddress].getUsdWithCache(amount);
  }

  /// @dev Retrieves the cached rate for a given token address.
  /// @param tokenAddress The address of the token for which to retrieve the rate.
  /// @return rate The cached rate as an integer.
  /// @return decimals The number of decimal places in the rate.
  function getCurrentRate(address tokenAddress) public view returns (int rate, uint8 decimals) {
    return tokenAddressToPaymentMethod[tokenAddress].getCurrentRate();
  }

  /// @notice Checks if the specified currency type is available
  /// @param tokenAddress The address of the currency type
  /// @return isAvailable A boolean indicating if the currency type is available
  function currencyTypeIsAvailable(address tokenAddress) public view returns (bool isAvailable) {
    return address(tokenAddressToPaymentMethod[tokenAddress]) != address(0);
  }

  function calculateLatestValueWithFee(
    address tokenAddress,
    uint value,
    uint commission
  ) public view returns (uint toPay, uint fee, int currencyRate, uint8 decimals) {
    (uint256 valueToPay, int256 rate, uint8 dec) = getFromUsdLatest(tokenAddress, value + commission);

    uint256 feeInCurrency = getFromUsd(tokenAddress, commission, rate, dec);
    return (valueToPay, feeInCurrency, rate, dec);
  }

  function calculateTripFinsish(
    Schemas.PaymentInfo memory paymentInfo,
    uint256 rentalityFee,
    uint insurancePriceInUsdCents,
    RentalityPromoService promoService
  ) public view returns (uint toHost, uint toGuest, uint toHostInUsd, uint toGuestInUsd, uint total) {
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
    if (discount == 100) {
      valueToGuest = 0;
      valueToGuestInUsdCents = 0;
    }
    return (valueToHost, valueToGuest, valueToHostInUsdCents, valueToGuestInUsdCents, totalIncome);
  }

  function calculateTripReject(
    Schemas.PaymentInfo memory paymentInfo,
    uint insurance,
    uint64 totalTax
  ) public pure returns (uint tripRejectValue) {
    uint64 valueToReturnInUsdCents = paymentInfo.priceWithDiscount +
      totalTax +
      uint64(paymentInfo.pickUpFee) +
      uint64(paymentInfo.dropOfFee) +
      paymentInfo.depositInUsdCents +
      uint64(insurance);

    return valueToReturnInUsdCents;
  }

  /// @notice Checks if the specified currency type is native
  /// @param tokenAddress The address of the currency type
  /// @return isEthCurrency A boolean indicating if the currency type is native
  function isETH(address tokenAddress) public pure returns (bool isEthCurrency) {
    return tokenAddress == address(0);
  }

  function getAllCurrencies() public view returns (Schemas.Currency[] memory availableOnPlatformCurrencies) {
    return availableCurrencies;
  }

  /// @notice Initializes the contract with the specified parameters
  /// @param _userService The address of the Rentality user service contract
  /// @param ethPaymentAddress The address of the ETH payment contract
  function initialize(
    address _userService,
    address ethPaymentAddress,
    string memory nativeCurrencyName
  ) public virtual initializer {
    tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethPaymentAddress);
    userService = IRentalityAccessControl(_userService);
    availableCurrencies.push(Schemas.Currency(address(0), nativeCurrencyName));
  }
}
