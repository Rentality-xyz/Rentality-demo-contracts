// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityPlatformHelperFacet {
  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function addUserDiscount(Schemas.BaseDiscount memory data) external;
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) external;
  function useKycCommission(address user) external;
  function addUserCurrency(address currency) external;
  function payKycCommission(address currency) external payable;
  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;
  function setPhoneNumber(address user, string memory phone, bool isVerified) external;
  function setEmail(address user, string memory email, bool isVerified) external;
  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) external;
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    bytes4 hash
  ) external;
  function setHostInsurance(uint insuranceId) external;
  function setPushToken(address user, string memory pushToken) external;
}
