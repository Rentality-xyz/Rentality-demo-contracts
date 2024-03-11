// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Schemas.sol';
import './IRentalityGeoParser.sol';
import './proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "./IRentalityGeoService.sol";

/// @title Rentality Geo Service Contract
/// @notice This contract provides geolocation services.
/// @dev It interacts with an external geolocation API and stores the results for cars.
contract RentalityGeoService is IRentalityGeoService, Initializable, UUPSAccess {
  /// @notice Mapping to store parsed geolocation data for each car ID.
  mapping(uint256 => Schemas.ParsedGeolocationData) public carIdToParsedGeolocationData;
  IRentalityGeoParser private geoParser;

  /// @notice Updates the address of the geolocation parser contract.
  /// @param _geoParser The address of the new geolocation parser contract.
  function updateParserAddress(address _geoParser) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    geoParser = IRentalityGeoParser(_geoParser);
  }

  /// @notice Retrieves the address of the current geolocation parser contract.
  /// @return The address of the current geolocation parser contract.
  function getGeoParserAddress() public view returns (address) {
    return address(geoParser);
  }

  /// @notice Updates the address of the user service contract.
  /// @param _userService The address of the new user service contract.
  function updateUserServiceAddress(address _userService) public {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    userService = IRentalityAccessControl(_userService);
  }

  /// @notice Retrieves the address of the current user service contract.
  /// @return The address of the current user service contract.
  function getUserServiceAddrss() public view returns (address) {
    return address(userService);
  }

  /// @notice Executes a request for geolocation data.
  /// @param addr The address for geolocation lookup.
  /// @param locationLatitude The latitude of the location.
  /// @param locationLongitude The longitude of the location.
  /// @param key The API key for accessing the geolocation service.
  /// @param carId The ID of the car for which geolocation is requested.
  /// @return requestId The ID of the Chainlink request.
  function executeRequest(
    string memory addr,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory key,
    uint256 carId
  ) public returns (bytes32 requestId) {
    return geoParser.executeRequest(addr, locationLatitude, locationLongitude, key, carId);
  }

  /// @notice Parses the geolocation response and stores parsed data.
  /// @param carId The ID of the car for which geolocation is parsed.
  function parseGeoResponse(uint256 carId) public {
    carIdToParsedGeolocationData[carId] = geoParser.parseGeoResponse(carId);
  }

  /// @notice Retrieves the validity of geolocation coordinates for a car.
  /// @param carId The ID of the car.
  /// @return validCoordinates A boolean indicating the validity of coordinates.
  function getCarCoordinateValidity(uint256 carId) public view returns (bool) {
    return carIdToParsedGeolocationData[carId].validCoordinates;
  }

  /// @notice Retrieves the city of geolocation for a car.
  /// @param carId The ID of the car.
  /// @return city The city name.
  function getCarCity(uint256 carId) public view returns (string memory) {
    return carIdToParsedGeolocationData[carId].city;
  }

  /// @notice Retrieves the state of geolocation for a car.
  /// @param carId The ID of the car.
  /// @return state The state name.
  function getCarState(uint256 carId) public view returns (string memory) {
    return carIdToParsedGeolocationData[carId].state;
  }

  /// @notice Retrieves the country of geolocation for a car.
  /// @param carId The ID of the car.
  /// @return country The country name.
  function getCarCountry(uint256 carId) public view returns (string memory) {
    return carIdToParsedGeolocationData[carId].country;
  }

  /// @notice Retrieves the latitude of geolocation for a car.
  /// @param carId The ID of the car.
  /// @return locationLat The latitude.
  function getCarLocationLatitude(uint256 carId) external view returns (string memory) {
    return carIdToParsedGeolocationData[carId].locationLat;
  }

  /// @notice Retrieves the longitude of geolocation for a car.
  /// @param carId The ID of the car.
  /// @return locationLng The longitude.
  function getCarLocationLongitude(uint256 carId) external view returns (string memory) {
    return carIdToParsedGeolocationData[carId].locationLng;
  }

  /// @notice Retrieves the time zone information associated with a specific car.
  /// @param carId The unique identifier of the car for which the time zone information is requested.
  /// @return timeZone A string representing the time zone of the specified car's geolocation data.
  function getCarTimeZoneId(uint256 carId) public view returns (string memory) {
    return carIdToParsedGeolocationData[carId].timeZoneId;
  }

  /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.
  /// @param _userService The address of the user service contract.
  /// @param _geoParser The address of the geolocation parser contract.
  function initialize(address _userService, address _geoParser) public initializer {
    userService = IRentalityAccessControl(_userService);
    geoParser = IRentalityGeoParser(_geoParser);
  }
}
