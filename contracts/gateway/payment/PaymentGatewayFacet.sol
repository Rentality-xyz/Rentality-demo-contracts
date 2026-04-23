// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/payment/RentalPaymentQuery.sol';
import '../../models/payment/RentalPaymentTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';
import '../../models/common/CommonTypes.sol';
import '../ARentalityContext.sol';
import './IPaymentGatewayFacet.sol';

interface IPaymentGatewayFacetSwaps {
  function getAllowedCurrencies() external view returns (RentalAllowedCurrencyDTO[] memory);
}

interface IPaymentGatewayFacetLegacyPaymentService {
  function getBaseDiscount(address user) external view returns (RentalBaseDiscount memory);
  function getTaxesInfoById(uint taxId) external view returns (RentalTaxesInfo memory);
  function addBaseDiscount(address user, RentalBaseDiscount memory data) external;
}

interface IPaymentGatewayFacetPromoService {
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (RentalCheckPromoDTO memory);
}

interface IPaymentGatewayFacetCurrencyConverter {
  function getAllCurrencies() external view returns (RentalCurrency[] memory);
}

interface IPaymentGatewayFacetUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

interface IPaymentGatewayFacetNotificationService {
  function emitEvent(EventType eType, uint256 id, uint8 objectStatus, address from, address to) external;
}

contract PaymentGatewayFacet is UUPSOwnable, ARentalityContext, IPaymentGatewayFacet {
  RentalPaymentQuery public paymentQuery;
  IPaymentGatewayFacetLegacyPaymentService public legacyPaymentService;
  IPaymentGatewayFacetPromoService public promoService;
  IPaymentGatewayFacetCurrencyConverter public currencyConverter;
  IPaymentGatewayFacetUserAccess public userAccess;
  IPaymentGatewayFacetNotificationService public notificationService;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(
      paymentQueryAddress,
      legacyPaymentServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      userAccessAddress,
      notificationServiceAddress
    );
  }

  function updateServiceAddresses(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) external onlyOwner {
    _setServiceAddresses(
      paymentQueryAddress,
      legacyPaymentServiceAddress,
      promoServiceAddress,
      currencyConverterAddress,
      userAccessAddress,
      notificationServiceAddress
    );
  }

  function getAvailableCurrency() external view returns (RentalAllowedCurrencyDTO[] memory) {
    return IPaymentGatewayFacetSwaps(paymentQuery.getSwapsAddress()).getAllowedCurrencies();
  }

  function getDiscount(address user) external view returns (RentalBaseDiscount memory) {
    return legacyPaymentService.getBaseDiscount(user);
  }

  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (RentalCheckPromoDTO memory)
  {
    return promoService.checkPromo(promo, startDateTime, endDateTime);
  }

  function getAvaibleCurrencies() external view returns (RentalCurrency[] memory) {
    return currencyConverter.getAllCurrencies();
  }

  function getTaxesInfoById(uint taxId) external view returns (RentalTaxesInfo memory) {
    return legacyPaymentService.getTaxesInfoById(taxId);
  }

  function addUserDiscount(RentalBaseDiscount memory data) external {
    address sender = _msgGatewaySender();
    legacyPaymentService.addBaseDiscount(sender, data);
    notificationService.emitEvent(EventType.Discount, 0, uint8(EventCreator.User), sender, sender);
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }

  function _setServiceAddresses(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress,
    address userAccessAddress,
    address notificationServiceAddress
  ) internal {
    paymentQuery = RentalPaymentQuery(paymentQueryAddress);
    legacyPaymentService = IPaymentGatewayFacetLegacyPaymentService(legacyPaymentServiceAddress);
    promoService = IPaymentGatewayFacetPromoService(promoServiceAddress);
    currencyConverter = IPaymentGatewayFacetCurrencyConverter(currencyConverterAddress);
    userAccess = IPaymentGatewayFacetUserAccess(userAccessAddress);
    notificationService = IPaymentGatewayFacetNotificationService(notificationServiceAddress);
  }
}
