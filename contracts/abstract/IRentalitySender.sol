// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../Schemas.sol';
import './IRentalityPlatform.sol';

interface IRentalitySender is IRentalityPlatform {
  // ------------------------------
  /// USER PROFILE quote functions
  /// ------------------------------

  function quoteSetKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    bytes4 hash
  ) external view returns (uint);

  function quoteSetPhoneNumber(address user, string memory phone, bool isVerified) external view returns (uint);


  function quoteUseKycCommission(address user) external view returns (uint);

  /// ------------------------------
  /// HOST CARS quote functions
  /// ------------------------------

  function quoteAddCar(Schemas.CreateCarRequest memory request) external view returns (uint);

  function quoteUpdateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external view returns (uint);

  function quoteUpdateCarTokenUri(uint256 carId, string memory tokenUri) external view returns (uint);

  function quoteAddUserDiscount(Schemas.BaseDiscount memory data) external view returns (uint);

  function quoteAddUserDeliveryPrices(
    uint64 underTwentyFiveMilesInUsdCents,
    uint64 aboveTwentyFiveMilesInUsdCents
  ) external view returns (uint);

  /// ------------------------------
  /// TRIPS quote functions - HOST
  /// ------------------------------

  function quoteApproveTripRequest(uint256 tripId) external view returns (uint);

  function quoteRejectTripRequest(uint256 tripId) external view returns (uint);

  function quoteCheckInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) external view returns (uint);

  function quoteCheckOutByHost(uint256 tripId, uint64[] memory panelParams) external view returns (uint);

  function quoteConfirmCheckOut(uint256 tripId) external view returns (uint);

  function quoteFinishTrip(uint256 tripId) external view returns (uint);

  /// ------------------------------
  /// TRIPS quote functions - GUEST
  /// ------------------------------

  function quoteCreateTripRequestWithDelivery(
    uint amount,
    Schemas.CreateTripRequestWithDelivery memory request,
    string memory promoCode
  ) external view returns (uint);

  function quoteCheckInByGuest(uint256 tripId, uint64[] memory panelParams) external view returns (uint);

  function quoteCheckOutByGuest(uint256 tripId, uint64[] memory panelParams) external view returns (uint);

  /// ------------------------------
  /// CLAIMS quote functions
  /// ------------------------------

  function quoteCreateClaim(
    Schemas.CreateClaimRequest memory request,
    bool isHostInsuranceClaim
  ) external view returns (uint);

  function quoteRejectClaim(uint256 claimId) external view returns (uint);

  function quotePayClaim(uint amount, uint256 claimId) external view returns (uint);

  /// ------------------------------
  /// INSURANCE quote functions
  /// ------------------------------

  function quoteSaveTripInsuranceInfo(
    uint tripId,
    Schemas.SaveInsuranceRequest memory insuranceInfo
  ) external view returns (uint);

  function quoteSaveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external view returns (uint);

  /// ------------------------------
  /// GENERAL quote functions
  /// ------------------------------

  function quoteUpdateServiceAddresses() external view returns (uint);

  function quoteSaveDimoTokenIds(uint[] memory tokenIds1, uint[] memory tokenIds2) external view returns (uint);

  function quoteAddUserCurrency(address currency) external view returns (uint);

  function quoteSetEmail(address user, string memory email, bool isVerified) external view returns (uint);

  function quoteSetHostInsurance(uint insuranceId) external view returns (uint);

  function quoteSetPushToken(address user, string memory pushToken) external view returns (uint);
}
