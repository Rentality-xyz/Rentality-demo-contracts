// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/CommonTypes.sol';
import '../../models/payment/PaymentTypes.sol';
import '../../models/trip/TripTypes.sol';
import '../upgradeable/UUPSOwnable.sol';
import './RentalityCurrencyType.sol';

interface IRentalityCurrencyConverterAccess {
  function isAdmin(address user) external view returns (bool);
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IRentalityCurrencyConverterPromo {
  function getPromoDiscountByTrip(uint256 tripId) external view returns (uint256);
}

contract RentalityCurrencyConverter is UUPSOwnable {
  IRentalityCurrencyConverterAccess public userAccess;
  mapping(address => ARentalityUpgradableCurrencyType) private tokenAddressToPaymentMethod;
  PaymentCurrency[] private availableCurrencies;
  mapping(address => UserCurrencyInfo) private userToCurrency;
  UserCurrencyInfo private defaultCurrency;

  error OnlyAdmin();
  error OnlyPlatform();
  error CurrencyNotAvailable(address currency);

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address userAccessAddress,
    address ethPaymentAddress,
    string memory nativeCurrencyName
  ) public initializer {
    __Ownable_init();
    userAccess = IRentalityCurrencyConverterAccess(userAccessAddress);
    tokenAddressToPaymentMethod[address(0)] = ARentalityUpgradableCurrencyType(ethPaymentAddress);
    availableCurrencies.push(PaymentCurrency(address(0), nativeCurrencyName));
    defaultCurrency = UserCurrencyInfo(address(0), nativeCurrencyName, false);
  }

  function addUserCurrency(address user, address currency) public {
    if (!userAccess.isRentalityPlatform(msg.sender)) {
      revert OnlyPlatform();
    }
    _requireAvailable(currency);
    userToCurrency[user] = UserCurrencyInfo(currency, _getCurrencyName(currency), true);
  }

  function getUserCurrency(address user) public view returns (UserCurrencyInfo memory) {
    UserCurrencyInfo memory userCurrency = userToCurrency[user];
    return userCurrency.initialized ? userCurrency : defaultCurrency;
  }

  function setDefaultCurrencyType(address currency) public {
    if (!userAccess.isAdmin(tx.origin)) {
      revert OnlyAdmin();
    }
    _requireAvailable(currency);
    defaultCurrency = UserCurrencyInfo(currency, _getCurrencyName(currency), false);
  }

  function addCurrencyType(address tokenAddress, address rentalityTokenService, string memory name) public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }

    tokenAddressToPaymentMethod[tokenAddress] = ARentalityUpgradableCurrencyType(rentalityTokenService);
    availableCurrencies.push(PaymentCurrency(tokenAddress, name));
  }

  function removeCurrencyType(address tokenAddress) public {
    if (!userAccess.isAdmin(msg.sender)) {
      revert OnlyAdmin();
    }

    delete tokenAddressToPaymentMethod[tokenAddress];
    for (uint256 i = 0; i < availableCurrencies.length; i++) {
      if (availableCurrencies[i].currency == tokenAddress) {
        for (uint256 j = i; j < availableCurrencies.length - 1; j++) {
          availableCurrencies[j] = availableCurrencies[j + 1];
        }
        availableCurrencies.pop();
        return;
      }
    }
  }

  function getFromUsdCents(
    address tokenAddress,
    uint256 amount,
    int256 currencyRate
  ) public view returns (uint256) {
    return _paymentMethod(tokenAddress).getFromUsdCents(amount, currencyRate);
  }

  function getCurrencyInfo(address currency) public view returns (UserCurrencyInfo memory currencyInfo) {
    currencyInfo = UserCurrencyInfo(currency, _getCurrencyName(currency), false);
  }

  function getDefaultCurrency() public view returns (UserCurrencyInfo memory) {
    return defaultCurrency;
  }

  function getLatest(address tokenAddress) public view returns (int256) {
    return _paymentMethod(tokenAddress).getLatest();
  }

  function getRate(address tokenAddress) public view returns (int256 rate, uint8 decimals) {
    return _paymentMethod(tokenAddress).getRate();
  }

  function getFromUsdCentsLatest(address tokenAddress, uint256 valueInUsdCents)
    public
    view
    returns (uint256 valueInCurrency, int256 rate, uint8 decimals)
  {
    return _paymentMethod(tokenAddress).getFromUsdCentsLatest(valueInUsdCents);
  }

  function getToUsdLatest(address tokenAddress, uint256 amount)
    public
    view
    returns (uint256 usdLatest, int256 rate, uint8 decimals)
  {
    return _paymentMethod(tokenAddress).getUsdFromLatest(amount);
  }

  function getToUsd(address tokenAddress, uint256 tokenValue, int256 tokenToUsd) public view returns (uint256) {
    return _paymentMethod(tokenAddress).getUsdCents(tokenValue, tokenToUsd);
  }

  function getCurrencyRateWithCache(address tokenAddress) public returns (int256 cachedRate, uint8 decimals) {
    return _paymentMethod(tokenAddress).getRateWithCache();
  }

  function getFromUsdCentsWithCache(address tokenAddress, uint256 valueInUsdCents)
    public
    returns (uint256 cachedValueInCurrency)
  {
    return _paymentMethod(tokenAddress).getFromUsdCentsWithCache(valueInUsdCents);
  }

  function getToUsdWithCache(address tokenAddress, uint256 amount) public returns (uint256 cachedValueInUsd) {
    return _paymentMethod(tokenAddress).getUsdWithCache(amount);
  }

  function getCurrentRate(address tokenAddress) public view returns (int256 rate, uint8 decimals) {
    return _paymentMethod(tokenAddress).getCurrentRate();
  }

  function currencyTypeIsAvailable(address tokenAddress) public view returns (bool) {
    return address(tokenAddressToPaymentMethod[tokenAddress]) != address(0);
  }

  function calculateLatestValueWithFee(address tokenAddress, uint256 value, uint256 commission)
    public
    view
    returns (uint256 toPay, uint256 fee, int256 currencyRate, uint8 decimals)
  {
    (uint256 valueToPay, int256 rate, uint8 dec) = getFromUsdCentsLatest(tokenAddress, value + commission);
    uint256 feeInCurrency = getFromUsdCents(tokenAddress, commission, rate);
    return (valueToPay, feeInCurrency, rate, dec);
  }

  function calculateTripFinsish(
    TripGatewayTypes.GatewayPaymentInfo memory paymentInfo,
    uint256 rentalityFee,
    uint256 feeOfPriceWithDiscount,
    uint256 insurancePriceInUsdCents,
    IRentalityCurrencyConverterPromo promoService
  ) public view returns (uint256 toHost, uint256 toGuest, uint256 toHostInUsd, uint256 toGuestInUsd, uint256 total, uint256) {
    uint256 discount = promoService.getPromoDiscountByTrip(paymentInfo.tripId);
    uint256 valueToHostInUsdCents = paymentInfo.priceWithDiscount
      + paymentInfo.pickUpFee
      + paymentInfo.dropOfFee
      + paymentInfo.resolveAmountInUsdCents
      - rentalityFee
      + insurancePriceInUsdCents;
    uint256 valueToGuestInUsdCents = paymentInfo.depositInUsdCents - paymentInfo.resolveAmountInUsdCents;
    uint256 valueToHost = getFromUsdCents(paymentInfo.currencyType, valueToHostInUsdCents, paymentInfo.currencyRate);
    uint256 tripCostValue = getFromUsdCents(
      paymentInfo.currencyType,
      paymentInfo.priceWithDiscount - feeOfPriceWithDiscount,
      paymentInfo.currencyRate
    );
    uint256 valueToGuest = getFromUsdCents(paymentInfo.currencyType, valueToGuestInUsdCents, paymentInfo.currencyRate);
    uint256 totalIncome = getFromUsdCents(
      paymentInfo.currencyType,
      valueToHostInUsdCents - paymentInfo.resolveAmountInUsdCents + rentalityFee,
      paymentInfo.currencyRate
    );
    if (discount == 100) {
      valueToGuest = 0;
      valueToGuestInUsdCents = 0;
    }
    return (valueToHost, valueToGuest, valueToHostInUsdCents, valueToGuestInUsdCents, totalIncome, tripCostValue);
  }

  function calculateTripReject(
    TripGatewayTypes.GatewayPaymentInfo memory paymentInfo,
    uint256 insurance,
    uint64 totalTax
  ) public pure returns (uint256) {
    return paymentInfo.priceWithDiscount
      + totalTax
      + paymentInfo.pickUpFee
      + paymentInfo.dropOfFee
      + paymentInfo.depositInUsdCents
      + insurance;
  }

  function isETH(address tokenAddress) public pure returns (bool) {
    return tokenAddress == address(0);
  }

  function getAllCurrencies() public view returns (PaymentCurrency[] memory) {
    return availableCurrencies;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityCurrencyConverterAccess(userAccessAddress);
  }

  function _paymentMethod(address tokenAddress) private view returns (ARentalityUpgradableCurrencyType) {
    ARentalityUpgradableCurrencyType paymentMethod = tokenAddressToPaymentMethod[tokenAddress];
    if (address(paymentMethod) == address(0)) {
      revert CurrencyNotAvailable(tokenAddress);
    }
    return paymentMethod;
  }

  function _requireAvailable(address currency) private view {
    if (!currencyTypeIsAvailable(currency)) {
      revert CurrencyNotAvailable(currency);
    }
  }

  function _getCurrencyName(address currency) private view returns (string memory) {
    for (uint256 i = 0; i < availableCurrencies.length; i++) {
      if (availableCurrencies[i].currency == currency) {
        return availableCurrencies[i].name;
      }
    }
    return '';
  }
}
