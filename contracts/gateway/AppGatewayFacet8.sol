// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../infrastructure/upgradeable/UUPSOwnable.sol';
import '../models/payment/PaymentQuery.sol';
import '../models/payment/PaymentTypes.sol';
import '../models/pricing/PricingTypes.sol';
import '../models/common/CommonTypes.sol';
import './ARentalityContext.sol';
import './payment/IPaymentGatewayFacet.sol';

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
}

interface IPaymentGatewayFacetCurrencyConverter {
  function getAllCurrencies() external view returns (PaymentCurrency[] memory);
}

interface IPaymentGatewayFacetUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IPaymentGatewayFacetNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract AppGatewayFacet8 is UUPSOwnable, ARentalityContext, IPaymentGatewayFacet {
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
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      paymentQueryAddress,
      pricingServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      userAccessAddress,
      notificationServiceAddress
    );
  }

  function updateServiceAddresses(
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
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

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }

  function _setServiceAddresses(
    address paymentQueryAddress,
    address pricingServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) internal {
    paymentQuery = PaymentQuery(paymentQueryAddress);
    pricingService = IPaymentGatewayFacetPricingService(pricingServiceAddress);
    promoService = IPaymentGatewayFacetPromoService(promoServiceAddress);
    currencyConverter = IPaymentGatewayFacetCurrencyConverter(currencyConverterAddress);
    userAccess = IPaymentGatewayFacetUserAccess(userAccessAddress);
    notificationService = IPaymentGatewayFacetNotificationService(notificationServiceAddress);
  }
}
