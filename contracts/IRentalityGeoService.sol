// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title RentalityGeoService
/// @notice This contract defines the interface for the Rentality Geo Service, which provides geo-verification for cars info in the Rentality platform.
/// @dev All functions in this interface are meant to be implemented by the Rentality Geo Service contract.
interface IRentalityGeoService {
  /// @notice Execute a request to verify geo-related information.
  /// @param addr The address for the geo-related request.
  /// @param key The key for the geo-related request.
  /// @param carId The ID of the car for which geo-related information is requested.
  /// @return A bytes32 value representing the requestId of the geo-related request.
  function executeRequest(string memory addr, string memory location, string memory key, uint256 carId) external returns (bytes32);

  /// @notice Get the validity of the coordinates for a specific car.
  /// @param carId The ID of the car.
  /// @return A boolean indicating the validity of the car's coordinates.
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);

  /// @notice Get the city of a specific car.
  /// @param carId The ID of the car.
  /// @return A string representing the city associated with the car.
  function getCarCity(uint256 carId) external view returns (string memory);

  /// @notice Get the state of a specific car.
  /// @param carId The ID of the car.
  /// @return A string representing the state associated with the car.
  function getCarState(uint256 carId) external view returns (string memory);

  /// @notice Get the country of a specific car.
  /// @param carId The ID of the car.
  /// @return A string representing the country associated with the car.
  function getCarCountry(uint256 carId) external view returns (string memory);

  /// @notice Get the time zone of of a specific car.
  /// @param carId The ID of the car.
  /// @return A string representing time zone id.
  function getCarTimeZoneId(uint256 carId) external view returns (string memory);
}
