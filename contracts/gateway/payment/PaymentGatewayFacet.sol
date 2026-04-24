// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/payment/PaymentMain.sol';
import '../../models/payment/PaymentQuery.sol';
import '../../models/payment/PaymentTypes.sol';
import '../../models/pricing/PricingTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../GatewayContext.sol';
import './IPaymentGatewayFacet.sol';

interface IPaymentGatewayFacetSwaps {
  function getAllowedCurrencies() external view returns (AllowedCurrencyDTO[] memory);
}

interface IPaymentGatewayFacetPricingService {
  function getBaseDiscount(address user) external view returns (PricingBaseDiscount memory);
  function getTaxesInfoById(uint taxId) external view returns (PricingTaxesInfo memory);
  function addBaseDiscount(address user, PricingBaseDiscount memory data) external;
}

interface IPaymentGatewayFacetPromoService {
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (PricingCheckPromoDTO memory);
  function addPrefix(string memory prefix, uint256 discount) external;
}

interface IPaymentGatewayFacetCurrencyConverter {
  function getAllCurrencies() external view returns (PaymentCurrency[] memory);
  function setDefaultCurrencyType(address currency) external;
}

interface IPaymentGatewayFacetUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IPaymentGatewayFacetNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract PaymentGatewayFacet is UUPSOwnable, GatewayContext, IPaymentGatewayFacet {
  PaymentMain public paymentMain;
  PaymentQuery public paymentQuery;
  IPaymentGatewayFacetPricingService public pricingService;
  IPaymentGatewayFacetPromoService public promoService;
  IPaymentGatewayFacetCurrencyConverter public currencyConverter;
  IPaymentGatewayFacetUserAccess public userAccess;
  IPaymentGatewayFacetNotificationService public notificationService;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address paymentMainAddress,
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      paymentMainAddress,
      paymentQueryAddress,
      pricingServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      userAccessAddress,
      notificationServiceAddress
    );
  }

  function updateServiceAddresses(
    address paymentMainAddress,
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      paymentMainAddress,
      paymentQueryAddress,
      pricingServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      userAccessAddress,
      notificationServiceAddress
    );
  }

  function getAvailableCurrency() external view returns (AllowedCurrencyDTO[] memory) {
    return IPaymentGatewayFacetSwaps(paymentQuery.getSwapsAddress()).getAllowedCurrencies();
  }

  function getDiscount(address user) external view returns (PricingBaseDiscount memory) {
    return pricingService.getBaseDiscount(user);
  }

  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (PricingCheckPromoDTO memory)
  {
    return promoService.checkPromo(promo, startDateTime, endDateTime);
  }

  function getAvaibleCurrencies() external view returns (PaymentCurrency[] memory) {
    return currencyConverter.getAllCurrencies();
  }

  function getTaxesInfoById(uint taxId) external view returns (PricingTaxesInfo memory) {
    return pricingService.getTaxesInfoById(taxId);
  }

  function addUserDiscount(PricingBaseDiscount memory data) external {
    address sender = _msgGatewaySender();
    pricingService.addBaseDiscount(sender, data);
    notificationService.emitEvent(EventType.Discount, 0, uint8(EventCreator.User), sender, sender);
  }

  function withdrawFromPlatform(uint256 amount, address currencyType) external {
    paymentMain.withdrawFromPlatform(amount, currencyType);
  }

  function withdrawAllFromPlatform(address currencyType) external {
    uint256 balance = currencyType == address(0)
      ? address(paymentMain).balance
      : IERC20(currencyType).balanceOf(address(paymentMain));
    paymentMain.withdrawFromPlatform(balance, currencyType);
  }

  function updatePromoData(string memory prefix, uint256 discount) external {
    promoService.addPrefix(prefix, discount);
  }

  function setDefaultCurrencyType(address currency) external {
    address sender = _msgGatewaySender();
    currencyConverter.setDefaultCurrencyType(currency);
    notificationService.emitEvent(EventType.Currency, 0, uint8(EventCreator.Admin), sender, sender);
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }

  function _setServiceAddresses(
    address paymentMainAddress,
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) internal {
    paymentMain = PaymentMain(paymentMainAddress);
    paymentQuery = PaymentQuery(paymentQueryAddress);
    pricingService = IPaymentGatewayFacetPricingService(pricingServiceAddress);
    promoService = IPaymentGatewayFacetPromoService(promoServiceAddress);
    currencyConverter = IPaymentGatewayFacetCurrencyConverter(currencyConverterAddress);
    userAccess = IPaymentGatewayFacetUserAccess(userAccessAddress);
    notificationService = IPaymentGatewayFacetNotificationService(notificationServiceAddress);
  }
}
