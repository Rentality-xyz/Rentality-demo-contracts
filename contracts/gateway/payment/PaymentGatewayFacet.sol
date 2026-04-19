// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../models/payment/RentalPaymentQuery.sol';
import '../../rentality_old/Schemas.sol';
import './IPaymentGatewayFacet.sol';

interface IPaymentGatewayFacetSwaps {
  function getAllowedCurrencies() external view returns (Schemas.AllowedCurrencyDTO[] memory);
}

interface IPaymentGatewayFacetLegacyPaymentService {
  function getBaseDiscount(address user) external view returns (Schemas.BaseDiscount memory);
  function getTaxesInfoById(uint taxId) external view returns (Schemas.TaxesInfoDTO memory);
}

interface IPaymentGatewayFacetPromoService {
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (Schemas.CheckPromoDTO memory);
}

interface IPaymentGatewayFacetCurrencyConverter {
  function getAllCurrencies() external view returns (Schemas.Currency[] memory);
}

contract PaymentGatewayFacet is UUPSOwnable, IPaymentGatewayFacet {
  RentalPaymentQuery public paymentQuery;
  IPaymentGatewayFacetLegacyPaymentService public legacyPaymentService;
  IPaymentGatewayFacetPromoService public promoService;
  IPaymentGatewayFacetCurrencyConverter public currencyConverter;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress
  ) public initializer {
    __Ownable_init();
    _setServiceAddresses(paymentQueryAddress, legacyPaymentServiceAddress, promoServiceAddress, currencyConverterAddress);
  }

  function updateServiceAddresses(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress
  ) external onlyOwner {
    _setServiceAddresses(paymentQueryAddress, legacyPaymentServiceAddress, promoServiceAddress, currencyConverterAddress);
  }

  function getAvailableCurrency() external view returns (Schemas.AllowedCurrencyDTO[] memory) {
    return IPaymentGatewayFacetSwaps(paymentQuery.getSwapsAddress()).getAllowedCurrencies();
  }

  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory) {
    return legacyPaymentService.getBaseDiscount(user);
  }

  function checkPromo(string memory promo, uint startDateTime, uint endDateTime)
    external
    view
    returns (Schemas.CheckPromoDTO memory)
  {
    return promoService.checkPromo(promo, startDateTime, endDateTime);
  }

  function getAvaibleCurrencies() external view returns (Schemas.Currency[] memory) {
    return currencyConverter.getAllCurrencies();
  }

  function getTaxesInfoById(uint taxId) external view returns (Schemas.TaxesInfoDTO memory) {
    return legacyPaymentService.getTaxesInfoById(taxId);
  }

  function _setServiceAddresses(
    address paymentQueryAddress,
    address legacyPaymentServiceAddress,
    address promoServiceAddress,
    address currencyConverterAddress
  ) internal {
    paymentQuery = RentalPaymentQuery(paymentQueryAddress);
    legacyPaymentService = IPaymentGatewayFacetLegacyPaymentService(legacyPaymentServiceAddress);
    promoService = IPaymentGatewayFacetPromoService(promoServiceAddress);
    currencyConverter = IPaymentGatewayFacetCurrencyConverter(currencyConverterAddress);
  }
}
