// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../Schemas.sol";
import "../../libraries/CurrencyConverterStorage.sol";
import "../../libraries/UserServiceStorage.sol";

contract RentalityCurrencyConverterFacet {


    function addUserCurrency(address currency) public {
        CurrencyConverterStorage.addUserCurrency(currency);
  }
  function getUserCurrency(address user) public view returns ( Schemas.UserCurrency memory currency) {
     return CurrencyConverterStorage.getUserCurrency(user);
  }

  function setDefaultCurrencyType(address currency) public {
    CurrencyConverterStorage.CurrencyConverterFaucetStorage storage s = CurrencyConverterStorage.accessStorage();
    require(UserServiceStorage.isAdmin(msg.sender), 'only for Admin');
    require(address(s.tokenAddressToPaymentMethod[currency]) != address(0), 'Currency not available.');
    s.defaultCurrency =  Schemas.UserCurrency(currency, false);
  }

  /// @notice Adds a new currency type with its associated Rentality token service contract address
  /// @param tokenAddress The address of the new currency type
  /// @param rentalityTokenService The address of the Rentality token service contract
  function addCurrencyType(address tokenAddress, address rentalityTokenService, string memory name) public {
    CurrencyConverterStorage.CurrencyConverterFaucetStorage storage s = CurrencyConverterStorage.accessStorage();
    require(UserServiceStorage.isAdmin(msg.sender), 'From manager contract only.');

    s.tokenAddressToPaymentMethod[tokenAddress] = ARentalityUpgradableCurrencyType(rentalityTokenService);
    s.availableCurrencies.push(Schemas.Currency(tokenAddress, name));
  }
  
    /// @dev Retrieves the cached rate for a given token address.
  /// @param tokenAddress The address of the token for which to retrieve the rate.
  /// @return rate The cached rate as an integer.
  /// @return decimals The number of decimal places in the rate.
  function getCurrentRate(address tokenAddress) public view returns (int rate, uint8 decimals) {
    CurrencyConverterStorage.CurrencyConverterFaucetStorage storage s = CurrencyConverterStorage.accessStorage();

    return s.tokenAddressToPaymentMethod[tokenAddress].getCurrentRate();
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
    return CurrencyConverterStorage.getFromUsd(tokenAddress, amount, currencyRate, decimals);
  }

    /// @notice Retrieves the equivalent amount in the specified currency type from the provided USD value
  /// @param tokenAddress The address of the currency type
  /// @param valueInUsdCents The value in USD cents to convert
  /// @return valueInCurrency The equivalent amount in the specified currency type, the corresponding currency rate, and decimals
  function getFromUsdLatest(
    address tokenAddress,
    uint256 valueInUsdCents
  ) public view returns (uint256 valueInCurrency, int256 rate, uint8 decimals) {
    return CurrencyConverterStorage.getFromUsdLatest(tokenAddress, valueInUsdCents);
  }

  /// @notice Retrieves the equivalent amount in USD cents from the provided currency type amount
  /// @param tokenAddress The address of the currency type
  /// @param amount The amount in the specified currency type
  /// @return usdLatest The equivalent amount in USD cents, the corresponding currency rate, and decimals
  function getToUsdLatest(
    address tokenAddress,
    uint256 amount
  ) public view returns (uint256 usdLatest, int256 rate, uint8 decimals) {
    return CurrencyConverterStorage.getToUsdLatest(tokenAddress, amount);
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
    return CurrencyConverterStorage.getToUsd(tokenAddress, tokenValue, tokenToUsd, decimals);
  }

   function getAvaibleCurrencies() public view returns (Schemas.Currency[] memory availableOnPlatformCurrencies) {
    CurrencyConverterStorage.CurrencyConverterFaucetStorage storage s = CurrencyConverterStorage.accessStorage();
    return s.availableCurrencies;
  }

}