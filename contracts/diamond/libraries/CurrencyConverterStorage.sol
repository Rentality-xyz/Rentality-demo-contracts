// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../payments/RentalityCurrencyType.sol';
import { Schemas } from '../../Schemas.sol';
import { LibDiamond } from './LibDiamond.sol';

library  CurrencyConverterStorage {
    struct CurrencyConverterFaucetStorage {
        mapping(address => ARentalityUpgradableCurrencyType) tokenAddressToPaymentMethod;

        Schemas.Currency[] availableCurrencies;

        mapping(address =>  Schemas.UserCurrency) userToCurrency;
        Schemas.UserCurrency defaultCurrency;
} 

   function addUserCurrency(address currency) internal {
         CurrencyConverterFaucetStorage storage s = accessStorage();
         require(address(s.tokenAddressToPaymentMethod[currency]) != address(0), 'Currency not available.');
         s.userToCurrency[msg.sender] =  Schemas.UserCurrency(currency, true);
  }
 function getUserCurrency(address user) internal view returns ( Schemas.UserCurrency memory currency) {
      CurrencyConverterFaucetStorage storage s = accessStorage();
      Schemas.UserCurrency memory userCurrency = s.userToCurrency[user];
     if(userCurrency.initialized) {
       return userCurrency;
     }
     return s.defaultCurrency;
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
  ) internal view returns (uint amountInCurrency) {
     CurrencyConverterFaucetStorage storage s = accessStorage();

    return s.tokenAddressToPaymentMethod[tokenAddress].getFromUsd(amount, currencyRate, decimals);
  }

  /// @notice Retrieves the latest rate of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return latestRate The latest rate of the currency type
  function getLatest(address tokenAddress) internal view returns (int latestRate) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getLatest();
  }

  /// @notice Retrieves the rate and decimals of the specified currency type
  /// @param tokenAddress The address of the currency type
  /// @return rate The rate and decimals of the currency type
  function getRate(address tokenAddress) internal view returns (int256 rate, uint8 decimals) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getRate();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return valueInCurrency The equivalent amount in the specified currency type, the corresponding currency rate, and decimals
  function getFromUsdLatest(
    address tokenAddress,
    uint256 valueInUsdCents
  ) internal view returns (uint256 valueInCurrency, int256 rate, uint8 decimals) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getFromUsdLatest(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return usdLatest The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getToUsdLatest(
    address tokenAddress,
    uint256 amount
  ) internal view returns (uint256 usdLatest, int256 rate, uint8 decimals) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getUsdFromLatest(amount);
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
  ) internal view returns (uint256 valueInUsd) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getUsd(tokenValue, tokenToUsd, decimals);
  }

  /// @notice Retrieves the currency rate and decimals of the specified currency type with cache
  /// @param tokenAddress The address of the currency type
  /// @return cachedRate The currency rate of the currency type
  /// @return decimals The currency decimals of the currency type
  function getCurrencyRateWithCache(address tokenAddress) internal returns (int256 cachedRate, uint8 decimals) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getRateWithCache();
  }

  /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value with cache
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return cachedValueInCurrency The equivalent amount in the specified currency type
  function getFromUsdWithCache(
    address tokenAddress,
    uint256 valueInUsdCents
  ) internal returns (uint256 cachedValueInCurrency) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getFromUsdWithCache(valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount with cache
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return cachedValueInUsd The equivalent amount in USD cents
  function getToUsdWithCache(address tokenAddress, uint256 amount) internal returns (uint256 cachedValueInUsd) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getUsdWithCache(amount);
  }

  /// @dev Retrieves the cached rate for a given token address.
  /// @param tokenAddress The address of the token for which to retrieve the rate.
  /// @return rate The cached rate as an integer.
  /// @return decimals The number of decimal places in the rate.
  function getCurrentRate(address tokenAddress) internal view returns (int rate, uint8 decimals) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.tokenAddressToPaymentMethod[tokenAddress].getCurrentRate();
  }

  /// @notice Checks if the specified currency type is available
  /// @param tokenAddress The address of the currency type
  /// @return isAvailable A boolean indicating if the currency type is available
  function currencyTypeIsAvailable(address tokenAddress) internal view returns (bool isAvailable) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return address(s.tokenAddressToPaymentMethod[tokenAddress]) != address(0);
  }

  function calculateLatestValueWithFee(
    address tokenAddress,
    uint value,
    uint commission
  ) internal view returns (uint toPay, uint fee, int currencyRate, uint8 decimals) {
    (uint256 valueToPay, int256 rate, uint8 dec) = getFromUsdLatest(tokenAddress, value + commission);

    uint256 feeInCurrency = getFromUsd(tokenAddress, commission, rate, dec);
    return (valueToPay, feeInCurrency, rate, dec);
  }

  function calculateTripFinsish(
    Schemas.PaymentInfo memory paymentInfo,
    uint256 rentalityFee,
    uint insurancePriceInUsdCents
  ) internal view returns (uint toHost, uint toGuest, uint toHostInUsd, uint toGuestInUsd, uint total) {
    // uint discount = promoService.getPromoDiscountByTrip(paymentInfo.tripId);
    uint discount = 0;

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
  ) internal pure returns (uint tripRejectValue) {
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
  function isETH(address tokenAddress) internal pure returns (bool isEthCurrency) {
    return tokenAddress == address(0);
  }

  function getAllCurrencies() internal view returns (Schemas.Currency[] memory availableOnPlatformCurrencies) {
    CurrencyConverterFaucetStorage storage s = accessStorage();
    return s.availableCurrencies;
  }



 function accessStorage() internal pure returns (CurrencyConverterFaucetStorage storage cs) {
        bytes32 position = LibDiamond.CURRENCY_CONVERTER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
   
}