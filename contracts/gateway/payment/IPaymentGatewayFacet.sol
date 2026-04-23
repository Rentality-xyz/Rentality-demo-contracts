// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/payment/RentalPaymentTypes.sol';
import '../../models/pricing/RentalPricingTypes.sol';

interface IPaymentGatewayFacet {
  function getAvailableCurrency() external view returns (RentalAllowedCurrencyDTO[] memory);
  function getDiscount(address user) external view returns (RentalBaseDiscount memory);
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) external view returns (RentalCheckPromoDTO memory);
  function getAvaibleCurrencies() external view returns (RentalCurrency[] memory);
  function getTaxesInfoById(uint taxId) external view returns (RentalTaxesInfo memory);
  function addUserDiscount(RentalBaseDiscount memory data) external;
}
