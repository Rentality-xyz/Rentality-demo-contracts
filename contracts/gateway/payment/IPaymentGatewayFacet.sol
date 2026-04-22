// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/Schemas.sol';

interface IPaymentGatewayFacet {
  function getAvailableCurrency() external view returns (Schemas.AllowedCurrencyDTO[] memory);
  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory);
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) external view returns (Schemas.CheckPromoDTO memory);
  function getAvaibleCurrencies() external view returns (Schemas.Currency[] memory);
  function getTaxesInfoById(uint taxId) external view returns (Schemas.TaxesInfoDTO memory);
  function addUserDiscount(Schemas.BaseDiscount memory data) external;
}
