// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/payment/PaymentTypes.sol';
import '../../models/pricing/PricingTypes.sol';

interface IPaymentGatewayFacet {
  function getAvailableCurrency() external view returns (AllowedCurrencyDTO[] memory);
  function getDiscount(address user) external view returns (PricingBaseDiscount memory);
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) external view returns (PricingCheckPromoDTO memory);
  function getAvaibleCurrencies() external view returns (PaymentCurrency[] memory);
  function getTaxesInfoById(uint taxId) external view returns (PricingTaxesInfo memory);
  function addUserDiscount(PricingBaseDiscount memory data) external;
  function withdrawFromPlatform(uint256 amount, address currencyType) external;
  function withdrawAllFromPlatform(address currencyType) external;
  function updatePromoData(string memory prefix, uint256 discount) external;
  function setDefaultCurrencyType(address currency) external;
}
