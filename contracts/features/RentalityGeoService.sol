// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import './IRentalityGeoParser.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityGeoService.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './RentalityLocationVerifier.sol';

/// @title Rentality Geo Service Contract
/// @notice This contract provides geolocation services.
/// @dev It interacts with an external geolocation API and stores the results for cars.
contract RentalityGeoService is IRentalityGeoService, Initializable, UUPSAccess {
  /// @notice Mapping to store parsed geolocation data for each car ID.
  mapping(uint256 => Schemas.ParsedGeolocationData) public carIdToParsedGeolocationData;
  IRentalityGeoParser private geoParser; // unused

  mapping(bytes32 => Schemas.LocationInfo) public locationDictionary;

  RentalityLocationVerifier private verifier;

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
  /// @return city The city name.
  function getCarCity(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].city;
  }

  /// @notice Retrieves the state of geolocation for a car.
  /// @return state The state name.
  function getCarState(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].state;
  }

  /// @notice Retrieves the country of geolocation for a car.
  /// @return country The country name.
  function getCarCountry(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].country;
  }

  /// @notice Retrieves the latitude of geolocation for a car.
  /// @return locationLat The latitude.
  function getCarLocationLatitude(bytes32 hash) external view returns (string memory) {
    return locationDictionary[hash].latitude;
  }

  /// @notice Retrieves the longitude of geolocation for a car.
  /// @return locationLng The longitude.
  function getCarLocationLongitude(bytes32 hash) external view returns (string memory) {
    return locationDictionary[hash].longitude;
  }

  /// @notice Retrieves the time zone information associated with a specific car.
  /// @return timeZone A string representing the time zone of the specified car's geolocation data.
  function getCarTimeZoneId(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].timeZoneId;
  }

  function createLocationInfo(Schemas.LocationInfo memory info) public returns (bytes32) {
    bytes32 hash = hashLocationInfo(info);
    locationDictionary[hash] = info;

    return hash;
  }
  function createSignedLocationInfo(Schemas.SignedLocationInfo memory info) public returns (bytes32) {
    if (info.signature.length == 0) {
      return bytes32('');
    }
    verifySignedLocationInfo(info);
    return createLocationInfo(info.locationInfo);
  }

  function hashLocationInfo(Schemas.LocationInfo memory info) public pure returns (bytes32) {
    if (bytes(info.longitude).length == 0) {
      return bytes32('');
    }
    bytes32 hash = keccak256(
      abi.encode(info.country, info.state, info.city, info.latitude, info.longitude, info.timeZoneId)
    );

    return hash;
  }

  function getLocationInfo(bytes32 hash) public view returns (Schemas.LocationInfo memory) {
    return locationDictionary[hash];
  }

  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) public view {
    verifier.verifySignedLocationInfo(locationInfo);
  }

  function setLocationVerifier(address _verifier) public {
    require(userService.isAdmin(tx.origin), 'only admin');
    verifier = RentalityLocationVerifier(_verifier);
  }
  function getVerifier() public view returns (RentalityLocationVerifier) {
    return verifier;
  }
  /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.
  /// @param _userService The address of the user service contract.
  function initialize(address _userService, address locationVerifier) public initializer {
    userService = IRentalityAccessControl(_userService);
    geoParser = IRentalityGeoParser(address(0));
    verifier = RentalityLocationVerifier(locationVerifier);
  }
}
