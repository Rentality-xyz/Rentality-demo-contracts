// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// For testing purposes
contract RentalityGeoMock {
  // Mapping to store the validity of car coordinates for each car ID.
  mapping(uint256 => bool) private carCoordinateValidity;

  // Mapping to store the city information for each car ID.
  mapping(uint256 => string) private carCity;

  // Mapping to store the state information for each car ID.
  mapping(uint256 => string) private carState;

  // Mapping to store the country information for each car ID.
  mapping(uint256 => string) private carCountry;

  // Mapping to store the time zone information for each car ID.
  mapping(uint256 => string) private carTimeZone;

  /// @dev Function: setCarCoordinateValidity
  /// @notice Sets the validity of car coordinates for a specific car ID.
  /// @param carId The ID of the car.
  /// @param validity The validity status to be set.
  function setCarCoordinateValidity(uint256 carId, bool validity) external {
    carCoordinateValidity[carId] = validity;
  }

  /// @dev Function: setCarCity
  /// @notice Sets the city information for a specific car ID.
  /// @param carId The ID of the car.
  /// @param city The city information to be set.
  function setCarCity(uint256 carId, string memory city) external {
    carCity[carId] = city;
  }

  /// @dev Function: setCarState
  /// @notice Sets the state information for a specific car ID.
  /// @param carId The ID of the car.
  /// @param state The state information to be set.
  function setCarState(uint256 carId, string memory state) external {
    carState[carId] = state;
  }

  /// @dev Function: setCarCountry
  /// @notice Sets the country information for a specific car ID.
  /// @param carId The ID of the car.
  /// @param country The country information to be set.
  function setCarCountry(uint256 carId, string memory country) external {
    carCountry[carId] = country;
  }

  /// @dev Function: executeRequest
  /// @notice Executes a mock request. Mock implementation, you can add your own logic if needed.
  /// @param addr The address parameter for the mock request.
  /// @param key The key parameter for the mock request.
  /// @param carId The ID of the car.
  /// @return The car ID as bytes32 (mock response).
  function executeRequest(
    string memory addr,
    string memory location,
    string memory key,
    uint256 carId
  ) external returns (bytes32) {
    // Mock implementation, you can add your own logic if needed
    return bytes32(carId);
  }

  /// @dev Function: getCarCoordinateValidity
  /// @notice Retrieves the validity of car coordinates for a specific car ID.
  /// @param carId The ID of the car.
  /// @return The validity status of car coordinates.
  function getCarCoordinateValidity(uint256 carId) external view returns (bool) {
    return carCoordinateValidity[carId];
  }

  /// @dev Function: getCarCity
  /// @notice Retrieves the city information for a specific car ID.
  /// @param carId The ID of the car.
  /// @return The city information.
  function getCarCity(uint256 carId) external view returns (string memory) {
    return carCity[carId];
  }

  /// @dev Function: getCarState
  /// @notice Retrieves the state information for a specific car ID.
  /// @param carId The ID of the car.
  /// @return The state information.
  function getCarState(uint256 carId) external view returns (string memory) {
    return carState[carId];
  }

  /// @dev Function: getCarCountry
  /// @notice Retrieves the country information for a specific car ID.
  /// @param carId The ID of the car.
  /// @return The country information.
  function getCarCountry(uint256 carId) external view returns (string memory) {
    return carCountry[carId];
  }
  function getCarTimeZoneId(uint256 carId) external view returns (string memory) {
    return carTimeZone[carId];
  }
}
