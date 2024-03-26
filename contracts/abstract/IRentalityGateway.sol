// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../RentalityTripService.sol';

/// @title RentalityGateway
/// @notice This contract defines the interface for the Rentality Gateway, which facilitates interactions between various services in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Gateway contract.
interface IRentalityGateway {
  /// @admin functions

  /// @notice This function retrieves the actual service addresses
  function updateServiceAddresses() external;

  /// @host functions

  /// @notice Add a new car to the platform.
  /// @param request The request parameters for creating a new car.
  /// @return The ID of the newly added car.
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint);

  /// @notice Update information for an existing car, without location.
  /// @param request the Update car parameters
  function updateCarInfo(Schemas.UpdateCarInfoRequest memory request) external;

  /// @notice Update information for an existing car with location
  /// @notice This sets geo verification status to false.
  /// @param request the Update car parameters
  /// @param location Single string that contains the car location
  /// @param geoApiKey the key to verify location by google geo api
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    string memory location,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory geoApiKey
  ) external;

  /// @notice Updates the token URI of a car. Only callable by hosts.
  /// @param carId The ID of the car to update.
  /// @param tokenUri The new token URI.
  function updateCarTokenUri(uint256 carId, string memory tokenUri) external;

  /// @notice Get the metadata URI for a specific car.
  /// @param carId The ID of the car.
  /// @return The metadata URI for the specified car.
  function getCarMetadataURI(uint256 carId) external view returns (string memory);

  /// @notice Get information about a specific car by ID.
  /// @param carId The ID of the car.
  /// @return CarInfo structure containing details about the specified car.
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfo memory);

  /// @notice Get information about all cars owned by the caller.
  /// @return An array of CarInfo structures containing details about the caller's cars.
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);

  /// @notice Burns (disables) a car. Only callable by hosts.
  /// @param carId The ID of the car to burn.
  //  function burnCar(uint256 carId) external;

  /// @notice Get information about all trips where the caller is the host.
  /// @return An array of Trip structures containing details about trips where the caller is the host.
  function getTripsAsHost() external view returns (Schemas.TripDTO[] memory);

  /// @notice Approve a trip request by its ID.
  /// @param tripId The ID of the trip to approve.
  function approveTripRequest(uint256 tripId) external;

  /// @notice Reject a trip request by its ID.
  /// @param tripId The ID of the trip to reject.
  function rejectTripRequest(uint256 tripId) external;

  /// @notice Performs check-in by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByHost(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Performs check-out by the host for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Finish a trip as the host.
  /// @param tripId The ID of the trip to finish.
  function finishTrip(uint256 tripId) external;

  /// @guest functions

  /// @notice Get information about all available cars.
  /// @return An array of CarInfo structures containing details about available cars.
  function getAvailableCars() external view returns (Schemas.CarInfo[] memory);

  /// @notice Retrieves information about all cars.
  /// @return An array of car information.
  function getAllCars() external view returns (Schemas.CarInfo[] memory);

  /// @notice Retrieves information about available cars for a specific user.
  /// @param user The address of the user.
  /// @return An array of available car information for the specified user.
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);

  /// @notice Search for available cars based on specified criteria.
  /// @param startDateTime The start date and time of the trip.
  /// @param endDateTime The end date and time of the trip.
  /// @param searchParams Additional parameters for searching available cars.
  /// @return An array of CarInfo structures containing details about available cars matching the criteria.
  function searchAvailableCars(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) external view returns (Schemas.SearchCar[] memory);

  /// @notice Searches for available cars for a specific user based on specified criteria.
  /// @param user The address of the user.
  /// @param startDateTime The start date and time of the search.
  /// @param endDateTime The end date and time of the search.
  /// @param searchParams Additional search parameters.
  /// @return An array of available car information meeting the search criteria for the specified user.
  function searchAvailableCarsForUser(
    address user,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams
  ) external view returns (Schemas.SearchCar[] memory);

  /// @notice Retrieves detailed information about a car.
  /// @param carId The ID of the car for which details are requested.
  /// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
  function getCarDetails(uint carId) external view returns (Schemas.CarDetails memory);

  /// @notice Create a trip request.
  /// @param request The request parameters for creating a new trip.
  function createTripRequest(Schemas.CreateTripRequest memory request) external payable;

  /// @notice Get information about all trips where the caller is the guest.
  /// @return An array of Trip structures containing details about trips where the caller is the guest.
  function getTripsAsGuest() external view returns (Schemas.TripDTO[] memory);

  /// @notice Performs check-in by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Performs check-out by the guest for a trip.
  /// @param tripId The ID of the trip.
  /// @param panelParams An array representing parameters related to fuel, odometer,
  /// and other relevant details depends on engine.
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external;

  /// @notice Get information about a specific trip.
  /// @param tripId The ID of the trip.
  /// @return Trip structure containing details about the specified trip.
  function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory);

  /// @notice Retrieves information about trips where the specified user is the guest.
  /// @param guest The address of the guest.
  /// @return An array of trip information for the specified guest.
  function getTripsByGuest(address guest) external view returns (Schemas.TripDTO[] memory);

  /// @notice Retrieves information about trips where the specified user is the host.
  /// @param host The address of the host.
  /// @return An array of trip information for the specified host.
  function getTripsByHost(address host) external view returns (Schemas.TripDTO[] memory);

  /// @notice Retrieves information about trips for a specific car.
  /// @param carId The ID of the car.
  /// @return An array of trip information for the specified car.
  function getTripsByCar(uint256 carId) external view returns (Schemas.Trip[] memory);

  /// @notice Creates a new claim through the Rentality platform.
  /// @dev This function delegates the claim creation to the Rentality platform contract.
  /// @param request Details of the claim to be created.
  function createClaim(Schemas.CreateClaimRequest memory request) external;

  /// @notice Rejects a specific claim through the Rentality platform.
  /// @dev This function delegates the claim rejection to the Rentality platform contract.
  /// @param claimId ID of the claim to be rejected.
  function rejectClaim(uint256 claimId) external;

  /// @notice Pays a specific claim through the Rentality platform, transferring funds and handling excess.
  /// @dev This function delegates the claim payment to the Rentality platform contract.
  /// @param claimId ID of the claim to be paid.
  function payClaim(uint256 claimId) external payable;

  /// @notice Updates the status of a specific claim through the Rentality platform.
  /// @dev This function delegates the claim update to the Rentality platform contract.
  /// @param claimId ID of the claim to be updated.
  function updateClaim(uint256 claimId) external;

  /// @notice Gets detailed information about a specific claim through the Rentality platform.
  /// @dev This function retrieves the claim information using the Rentality platform contract.
  /// @param claimId ID of the claim.
  /// @return Full information about the claim.
  function getClaim(uint256 claimId) external view returns (Schemas.FullClaimInfo memory);

  /// @notice Gets an array of claims associated with a specific trip through the Rentality platform.
  /// @dev This function retrieves an array of detailed claim information for the given trip using the Rentality platform contract.
  /// @param tripId ID of the trip.
  /// @return Array of detailed claim information.
  function getClaimsByTrip(uint256 tripId) external view returns (Schemas.FullClaimInfo[] memory);

  /// @notice Retrieves all claims where the caller is the host.
  /// @dev The caller is assumed to be the host of the claims.
  /// @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAsHost() external view returns (Schemas.FullClaimInfo[] memory);

  ///  @notice Retrieves all claims where the caller is the guest.
  ///  @dev The caller is assumed to be the guest of the claims.
  ///  @return An array of FullClaimInfo containing information about each claim.
  function getMyClaimsAsGuest() external view returns (Schemas.FullClaimInfo[] memory);

  /// @notice Get contact information for a trip.
  /// @param tripId The ID of the trip.
  /// @return guestPhoneNumber The phone number of the guest associated with the trip.
  /// @return hostPhoneNumber The phone number of the host associated with the trip.
  function getTripContactInfo(
    uint256 tripId
  ) external view returns (string memory guestPhoneNumber, string memory hostPhoneNumber);

  /// @notice Set KYC (Know Your Customer) information for the caller.
  /// @param name The name of the caller.
  /// @param surname The surname of the caller.
  /// @param mobilePhoneNumber The mobile phone number of the caller.
  /// @param profilePhoto The URL of the caller's profile photo.
  /// @param licenseNumber The driver's license number of the caller.
  /// @param expirationDate The expiration date of the caller's driver's license.
  /// @param isTCPassed Indicates whether the user has agreed to the terms of service for the platform
  function setKYCInfo(
    string memory name,
    string memory surname,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory licenseNumber,
    uint64 expirationDate,
    bool isTCPassed
  ) external;

  /// @notice Get KYC (Know Your Customer) information for a specific user.
  /// @param user The address of the user.
  /// @return KYCInfo structure containing details about the KYC information of the specified user.
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);

  /// @notice Get KYC (Know Your Customer) information for the caller.
  /// @return KYCInfo structure containing details about the KYC information of the caller.
  function getMyKYCInfo() external view returns (Schemas.KYCInfo memory);

  /// @notice Retrieves chat information for the caller acting as a host.
  /// @return An array of chat information.
  function getChatInfoForHost() external view returns (Schemas.ChatInfo[] memory);

  /// @notice Retrieves chat information for the caller acting as a guest.
  /// @return An array of chat information.
  function getChatInfoForGuest() external view returns (Schemas.ChatInfo[] memory);

  /// @notice Retrieves the cars owned by a specific host.
  /// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
  /// @param host The address of the host for whom to retrieve the cars.
  /// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);
}
