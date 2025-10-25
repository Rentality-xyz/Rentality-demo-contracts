// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Schemas.sol';

/// @title IRentalityPlatform
/// @notice Interface containing only write functions from RentalityGateway
interface IRentalityPlatform {
  
  /// ------------------------------
  /// USER PROFILE functions
  /// ------------------------------

  /// @notice Set KYC (Know Your Customer) information for the caller
  /// @param nickName The nickname of the user
  /// @param mobilePhoneNumber The mobile phone number of the user
  /// @param profilePhoto The profile photo URL of the user
  /// @param email The email of the user
  /// @param TCSignature The signature of the Terms and Conditions
  /// @param hash Hash of the terms and conditions
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    bytes4 hash
  ) external;

  /// @notice Set phone number for a user
  /// @param user The address of the user
  /// @param phone The phone number to set
  /// @param isVerified Whether the phone number is verified
  function setPhoneNumber(address user, string memory phone, bool isVerified) external;

  /// @notice Pays the KYC commission
  /// @param currency The address of the currency used for payment
  function payKycCommission(address currency) external payable;

  /// @notice Uses the KYC commission for a specific user
  /// @param user The address of the user whose KYC commission will be used
  function useKycCommission(address user) external;

  /// ------------------------------
  /// HOST CARS functions
  /// ------------------------------

  /// @notice Add a new car to the platform
  /// @param request The request parameters for creating a new car
  /// @return newTokenId The ID of the newly added car
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint newTokenId);

  /// @notice Update information for an existing car with location
  /// @param request The update car parameters
  /// @param location Single string that contains the car location
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;

  /// @notice Updates the token URI for a specific car
  /// @param carId The ID of the car whose token URI is being updated
  /// @param tokenUri The new token URI to be associated with the car
  function updateCarTokenUri(uint256 carId, string memory tokenUri) external;

  /// @notice Adds a user discount
  /// @param data The discount data
  function addUserDiscount(Schemas.BaseDiscount memory data) external;

  /// @notice Adds user delivery prices
  /// @param underTwentyFiveMilesInUsdCents The delivery price in USD cents for distances under 25 miles
  /// @param aboveTwentyFiveMilesInUsdCents The delivery price in USD cents for distances above 25 miles
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;

  /// ------------------------------
  /// TRIPS functions - HOST
  /// ------------------------------

  /// @notice Approve a trip request by its ID
  /// @param tripId The ID of the trip to approve
  function approveTripRequest(uint256 tripId) external;

  /// @notice Reject a trip request by its ID
  /// @param tripId The ID of the trip to reject
  function rejectTripRequest(uint256 tripId) external;

  /// @notice Allows the host to perform a check-in for a specific trip
  /// @param tripId The unique identifier for the trip being checked in
  /// @param panelParams An array of numeric parameters representing important vehicle details
  /// @param insuranceCompany The name of the insurance company covering the vehicle
  /// @param insuranceNumber The insurance policy number
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) external;

  /// @notice Performs check-out by the host for a trip
  /// @param tripId The ID of the trip
  /// @param panelParams An array representing parameters related to fuel, odometer, and other relevant details
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Confirms check-out for a trip
  /// @param tripId The ID of the trip
  function confirmCheckOut(uint256 tripId) external;

  /// @notice Finish a trip as the host
  /// @param tripId The ID of the trip to finish
  function finishTrip(uint256 tripId) external;

  /// ------------------------------
  /// TRIPS functions - GUEST
  /// ------------------------------

  /// @notice Create a trip request with delivery
  /// @param request The request parameters for creating a new trip
  /// @param promoCode Optional promo code for discount
  function createTripRequestWithDelivery(
    Schemas.CreateTripRequestWithDelivery memory request,
    string memory promoCode
  ) external payable;

  /// @notice Performs check-in by the guest for a trip
  /// @param tripId The ID of the trip
  /// @param panelParams An array representing parameters related to fuel, odometer, and other relevant details
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Performs check-out by the guest for a trip
  /// @param tripId The ID of the trip
  /// @param panelParams An array representing parameters related to fuel, odometer, and other relevant details
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// ------------------------------
  /// CLAIMS functions
  /// ------------------------------

  /// @notice Creates a new claim through the Rentality platform
  /// @param request Details of the claim to be created
  /// @param isHostInsuranceClaim Whether this is a host insurance claim
  function createClaim(Schemas.CreateClaimRequest memory request, bool isHostInsuranceClaim) external;

  /// @notice Rejects a specific claim through the Rentality platform
  /// @param claimId ID of the claim to be rejected
  function rejectClaim(uint256 claimId) external;

  /// @notice Pays a specific claim through the Rentality platform
  /// @param claimId ID of the claim to be paid
  function payClaim(uint256 claimId) external payable;

  /// ------------------------------
  /// INSURANCE functions
  /// ------------------------------

  /// @notice Saves insurance information related to a specific trip
  /// @param tripId The ID of the trip for which the insurance information is being saved
  /// @param insuranceInfo A struct containing the details of the insurance to be saved
  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) external;

  /// @notice Saves insurance information for a guest
  /// @param insuranceInfo A struct containing the details of the insurance requested by the guest
  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external;

  /// ------------------------------
  /// GENERAL functions
  /// ------------------------------

  /// @notice This function retrieves the actual service addresses
  function updateServiceAddresses() external;

  /// @notice Save DIMO token IDs
  /// @param tokenIds1 First array of token IDs
  /// @param tokenIds2 Second array of token IDs
  function saveDimoTokenIds(uint[] memory tokenIds1, uint[] memory tokenIds2) external;

  /// @notice Add user currency
  /// @param currency The address of the currency to add
  function addUserCurrency(address currency) external;

  /// @notice Set email for a user
  /// @param user The address of the user
  /// @param email The email to set
  /// @param isVerified Whether the email is verified
  function setEmail(address user, string memory email, bool isVerified) external;

  /// @notice Set host insurance
  /// @param insuranceId The ID of the insurance to set
  function setHostInsurance(uint insuranceId) external;

  /// @notice Set push token for a user
  /// @param user The address of the user
  /// @param pushToken The push token to set
  function setPushToken(address user, string memory pushToken) external;
}