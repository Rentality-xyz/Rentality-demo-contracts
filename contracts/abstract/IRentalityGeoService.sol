// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../features/RentalityLocationVerifier.sol';

/// @title RentalityGeoService
/// @notice This contract defines the interface for the Rentality Geo Service, which provides geo-verification for cars info in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Geo Service contract.
interface IRentalityGeoService {
  /// @notice Updates the address of the GeoParser contract.
  /// @param newGeoParserAddress The new address of the GeoParser contract.
  function updateParserAddress(address newGeoParserAddress) external;

  /// @notice Execute a request to verify geo-related information.
  /// @param addr The address for the geo-related request.
  /// @param key The key for the geo-related request.
  /// @param locationLatitude The latitude of the location associated with the request.
  /// @param locationLongitude The longitude of the location associated with the request.
  /// @param carId The ID of the car for which geo-related information is requested.
  /// @return A bytes32 value representing the requestId of the geo-related request.
  function executeRequest(
    string memory addr,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory key,
    uint256 carId
  ) external returns (bytes32);

  /// @notice Parse the geo-related response for a given car ID.
  /// @param carId The ID of the car for which the geo-related response is parsed.
  function parseGeoResponse(uint256 carId) external;

  /// @notice Get the validity of the coordinates for a specific car.
  /// @param carId The ID of the car.
  /// @return A boolean indicating the validity of the car's coordinates.
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);

  /// @notice Get the city of a specific car.
  /// @param hash of locationInfo
  /// @return A string representing the city associated with the car.
  function getCarCity(bytes32 hash) external view returns (string memory);

  /// @notice Get the state of a specific car.
  /// @param hash of locationInfo
  /// @return A string representing the state associated with the car.
  function getCarState(bytes32 hash) external view returns (string memory);

  /// @notice Get the country of a specific car.
  /// @param hash of locationInfo
  /// @return A string representing the country associated with the car.
  function getCarCountry(bytes32 hash) external view returns (string memory);

  /// @notice Get the time zone of of a specific car.
  /// @param hash of locationInfo
  /// @return A string representing time zone id.
  function getCarTimeZoneId(bytes32 hash) external view returns (string memory);

  /// @notice Retrieves the latitude of the location associated with a car.
  /// @param hash of locationInfo
  /// @return locationLat A string representing the latitude of the car's location.
  function getCarLocationLatitude(bytes32 hash) external view returns (string memory);

  /// @notice Retrieves the longitude of the location associated with a car.
  /// @param hash of locationInfo
  /// @return locationLng A string representing the longitude of the car's location.
  function getCarLocationLongitude(bytes32 hash) external view returns (string memory);

  /// @notice save and return hash of locationInfo
  /// @param info struct of location data
  /// @return hash of locationInfo struct
  function createLocationInfo(Schemas.LocationInfo memory info) external returns (bytes32);

  function createSignedLocationInfo(Schemas.SignedLocationInfo memory info) external returns (bytes32);

  /// @notice create hash of locationInfo
  /// @param info struct of location data
  /// @return hash of locationInfo struct
  function hashLocationInfo(Schemas.LocationInfo memory info) external returns (bytes32);

  /// @notice return location data by it hash
  /// @param hash of specific location info
  /// @return location data
  function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);

  function getVerifier() external view returns (RentalityLocationVerifier);

  /// @notice verify signed location info or revert
  /// @param signed location data
  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory signed) external view;
}
