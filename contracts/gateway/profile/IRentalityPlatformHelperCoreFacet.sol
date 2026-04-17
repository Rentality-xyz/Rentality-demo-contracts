// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface IRentalityPlatformHelperCoreFacet {
  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function addUserDiscount(Schemas.BaseDiscount memory data) external;
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) external;
  function addUserCurrency(address currency) external;
  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;
  function setHostInsurance(uint insuranceId) external;
}
