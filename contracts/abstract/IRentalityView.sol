// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';
import '../Schemas.sol';

interface IRentalityView {
  /// @dev Returns the metadata URI for a car.
  /// @param carId The ID of the car.
  function getCarMetadataURI(uint256 carId) external view returns (string memory);

  /// @dev Retrieves detailed information about a car by ID.
  /// @param carId The ID of the car.
  /// @return CarInfo structure with car details.
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);

  /// @dev Gets the list of cars owned by the caller.
  /// @return Array of CarInfoDTO structures with owned car details.
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);

  /// @dev Retrieves trips where the caller is the host.
  /// @return Array of TripDTO structures with trip details.
  function getTripsAsHost() external view returns (Schemas.TripDTO[] memory);

  /// @dev Retrieves the receipt for a specific trip.
  /// @param tripId The ID of the trip.
  /// @return TripReceiptDTO structure with receipt details.
  function getTripReceipt(uint tripId) external view returns (Schemas.TripReceiptDTO memory);

  /// @dev Retrieves a list of available cars for rent.
  /// @return Array of CarInfo structures with available car details.
  function getAvailableCars() external view returns (Schemas.CarInfo[] memory);

  /// @dev Retrieves information about all cars on the platform.
  /// @return Array of CarInfo structures with all car details.
  function getAllCars() external view returns (Schemas.CarInfo[] memory);

  /// @dev Retrieves available cars for a specific user.
  /// @param user The address of the user.
  /// @return Array of CarInfo structures with available car details.
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);

  /// @dev Searches for available cars based on time range and search parameters.
  /// @param startDateTime Start time of the search window.
  /// @param endDateTime End time of the search window.
  /// @param searchParams Search parameters for the car.
  /// @return Array of SearchCarWithDistance structures with matched cars.
  function searchAvailableCars(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) external view returns (Schemas.SearchCarWithDistance[] memory);

  /// @dev Gets detailed information about a specific car.
  /// @param carId The ID of the car.
  /// @return CarDetails structure with car details.
  function getCarDetails(uint carId) external view returns (Schemas.CarDetails memory);

  /// @dev Retrieves delivery data for a specific car.
  /// @param carId The ID of the car.
  /// @return DeliveryData structure with delivery information.
  function getDeliveryData(uint carId) external view returns (Schemas.DeliveryData memory);

  /// @dev Gets delivery prices set by a user.
  /// @param user The address of the user.
  /// @return DeliveryPrices structure with delivery cost details.
  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory);

  /// @dev Retrieves trips where the caller is the guest.
  /// @return Array of TripDTO structures with trip details.
  function getTripsAsGuest() external view returns (Schemas.TripDTO[] memory);

  /// @dev Retrieves details of a specific trip.
  /// @param tripId The ID of the trip.
  /// @return TripDTO structure with trip details.
  function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory);

  /// @dev Retrieves claims where the caller is the host.
  /// @return Array of FullClaimInfo structures with claim details.
  function getMyClaimsAsHost() external view returns (Schemas.FullClaimInfo[] memory);

  /// @dev Retrieves claims where the caller is the guest.
  /// @return Array of FullClaimInfo structures with claim details.
  function getMyClaimsAsGuest() external view returns (Schemas.FullClaimInfo[] memory);

  /// @dev Retrieves contact information for a specific trip.
  /// @param tripId The ID of the trip.
  /// @return Host's contact information in (string, string) format.
  function getTripContactInfo(uint256 tripId) external view returns (string memory, string memory);

  /// @dev Retrieves KYC information of the caller.
  /// @return KYCInfo structure with KYC details.
  function getMyKYCInfo() external view returns (Schemas.KYCInfo memory);

  /// @dev Retrieves chat information for the caller as a host.
  /// @return Array of ChatInfo structures with chat details.
  function getChatInfoForHost() external view returns (Schemas.ChatInfo[] memory);

  /// @dev Retrieves chat information for the caller as a guest.
  /// @return Array of ChatInfo structures with chat details.
  function getChatInfoForGuest() external view returns (Schemas.ChatInfo[] memory);

  /// @dev Retrieves all cars associated with a specific host.
  /// @param host The address of the host.
  /// @return Array of PublicHostCarDTO structures with host's car details.
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);

  /// @dev Gets the owner of the platform.
  /// @return The address of the owner.
  function owner() external view returns (address);

  /// @dev Calculates trip payments based on car ID, days, and currency.
  /// @param carId The ID of the car.
  /// @param daysOfTrip Number of days of the trip.
  /// @param currency The address of the currency.
  /// @return CalculatePaymentsDTO structure with calculated payment details.
  function calculatePayments(
    uint carId,
    uint64 daysOfTrip,
    address currency
  ) external view returns (Schemas.CalculatePaymentsDTO memory);

  /// @dev Calculates payments including delivery for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip Number of days of the trip.
  /// @param currency The address of the currency.
  /// @param pickUpLocation Pick-up location info.
  /// @param returnLocation Return location info.
  /// @return CalculatePaymentsDTO structure with payment details.
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation
  ) external view returns (Schemas.CalculatePaymentsDTO memory);

  /// @dev Retrieves any available discount for a user.
  /// @param user The address of the user.
  /// @return BaseDiscount structure with discount information.
  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory);

  /// @dev Searches for available cars with delivery options.
  /// @param startDateTime Start time of the search window.
  /// @param endDateTime End time of the search window.
  /// @param searchParams Search parameters for the car.
  /// @param pickUpInfo Pick-up location info.
  /// @param returnInfo Return location info.
  /// @return Array of SearchCarWithDistance structures with matched cars.
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.SearchCarWithDistance[] memory);

  /// @dev Calculates the KYC commission for a specific currency.
  /// @param currency The address of the currency.
  /// @return Commission amount in specified currency.
  function calculateKycCommission(address currency) external view returns (uint);

  /// @dev Retrieves the default KYC commission amount.
  /// @return Commission amount.
  function getKycCommission() external view returns (uint);

  /// @dev Checks if a user has paid the KYC commission.
  /// @param user The address of the user.
  /// @return Boolean indicating commission payment status.
  function isKycCommissionPaid(address user) external view returns (bool);

  /// @dev Retrieves the caller's complete KYC information.
  /// @return FullKYCInfoDTO structure with full KYC details.
  function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory);

  /// @dev Calculates the claim value for a specific claim.
  /// @param claimId The ID of the claim.
  /// @return Calculated claim value.
  function calculateClaimValue(uint claimId) external view returns (uint);
}
