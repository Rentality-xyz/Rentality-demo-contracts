// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/pricing/PricingTypes.sol';

interface IPricingGatewayFacet {
  function setPlatformFeeInPPM(uint32 valueInPPM) external;
  function getPlatformFeeInPPM() external view returns (uint32);
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxes(uint256 taxesId, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxesDTO(uint256 taxesId, uint64 daysOfTrip, uint64 value)
    external
    view
    returns (uint64 totalTax, PricingTaxValue[] memory taxValues);
  function setDefaultDiscount(PricingBaseDiscount memory newDiscounts) external;
  function addTaxes(string memory location, PricingTaxesLocationType locationType, PricingTaxValue[] memory taxes)
    external;
}
