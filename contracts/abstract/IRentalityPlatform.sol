// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';
import '../Schemas.sol';

interface IRentalityPlatform {
  /// @dev Updates the service addresses used by the platform.
  function updateServiceAddresses() external;

  /// @dev Adds a new car to the platform.
  /// @param request The CreateCarRequest structure with car details.
  /// @return The car ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint);

  /// @dev Updates information of an existing car.
  /// @param request The UpdateCarInfoRequest structure with updated car details.
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) external;

  /// @dev Updates car information along with location details.
  /// @param request The UpdateCarInfoRequest structure with updated car details.
  /// @param location SignedLocationInfo containing verified location data.
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;

  /// @dev Approves a trip request.
  /// @param tripId The ID of the trip request to approve.
  function approveTripRequest(uint256 tripId) external;

  /// @dev Rejects a trip request.
  /// @param tripId The ID of the trip request to reject.
  function rejectTripRequest(uint256 tripId) external;

  /// @dev Host check-in for a trip, including car condition details and insurance info.
  /// @param tripId The ID of the trip being checked in.
  /// @param panelParams Car's panel parameters recorded during check-in.
  /// @param insuranceCompany Name of the insurance company.
  /// @param insuranceNumber Insurance policy number.
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) external;

  /// @dev Host check-out for a trip, recording car's panel parameters.
  /// @param tripId The ID of the trip being checked out.
  /// @param panelParams Car's panel parameters recorded during check-out.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;

  /// @dev Guest confirms the completion of a trip after host's check-out.
  /// @param tripId The ID of the trip to confirm check-out for.
  function confirmCheckOut(uint256 tripId) external;

  /// @dev Marks the trip as finished.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId) external;

  /// @dev Creates a new trip request.
  /// @param request The CreateTripRequest structure with trip details.
  function createTripRequest(Schemas.CreateTripRequest memory request) external payable;

  /// @dev Creates a new trip request with delivery option.
  /// @param request The CreateTripRequestWithDelivery structure with trip and delivery details.
  function createTripRequestWithDelivery(Schemas.CreateTripRequestWithDelivery memory request) external payable;

  /// @dev Adds delivery pricing for the user based on mileage.
  /// @param underTwentyFiveMilesInUsdCents Price for delivery within 25 miles, in USD cents.
  /// @param aboveTwentyFiveMilesInUsdCents Price for delivery beyond 25 miles, in USD cents.
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;

  /// @dev Guest check-in for a trip, recording car's panel parameters.
  /// @param tripId The ID of the trip being checked in.
  /// @param panelParams Car's panel parameters recorded during check-in.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @dev Guest check-out for a trip, recording car's panel parameters.
  /// @param tripId The ID of the trip being checked out.
  /// @param panelParams Car's panel parameters recorded during check-out.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @dev Creates a claim for a trip.
  /// @param request The CreateClaimRequest structure with claim details.
  function createClaim(Schemas.CreateClaimRequest memory request) external;

  /// @dev Rejects an existing claim.
  /// @param claimId The ID of the claim to reject.
  function rejectClaim(uint256 claimId) external;

  /// @dev Pays out a claim.
  /// @param claimId The ID of the claim to pay.
  function payClaim(uint256 claimId) external payable;

  /// @dev Sets the user's KYC information.
  /// @param nickName The user's nickname.
  /// @param mobilePhoneNumber The user's mobile phone number.
  /// @param profilePhoto URL to the user's profile photo.
  /// @param TCSignature The signature of the terms and conditions.
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    bytes memory TCSignature
  ) external;

  /// @dev Sets Civic KYC information for a specific user.
  /// @param user The address of the user.
  /// @param civicKycInfo CivicKYCInfo structure containing KYC details.
  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) external;

  /// @dev Adds a discount for the user.
  /// @param data BaseDiscount structure with discount details.
  function addUserDiscount(Schemas.BaseDiscount memory data) external;

  /// @dev Pays the KYC commission using a specified currency.
  /// @param currency The address of the currency to use.
  function payKycCommission(address currency) external payable;

  /// @dev Consumes KYC commission for a specified user.
  /// @param user The address of the user.
  function useKycCommission(address user) external;
}
