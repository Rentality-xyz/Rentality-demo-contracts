// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';

/// @title Rentality Geo Parser Interface
/// @notice This interface defines the methods for interacting with the Rentality Geo Parser contract.
interface IRentalityGeoParser {
  /// @notice Executes a request to obtain geolocation data.
  /// @param addr The address for the geolocation request.
  /// @param locationLatitude The latitude of the location.
  /// @param locationLongitude The longitude of the location.
  /// @param key The key for accessing the geolocation service.
  /// @param carId The ID of the car for which geolocation is requested.
  /// @return requestId The ID of the request.
  function executeRequest(
    string memory addr,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory key,
    uint256 carId
  ) external returns (bytes32);

  /// @notice Parses the geolocation response for a specific car ID.
  /// @param carId The ID of the car for which geolocation response is parsed.
  /// @return Parsed geolocation data for the specified car ID.
  function parseGeoResponse(uint256 carId) external view returns (Schemas.ParsedGeolocationData memory);
}
