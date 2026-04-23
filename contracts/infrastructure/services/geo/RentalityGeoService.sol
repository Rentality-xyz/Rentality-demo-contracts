// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../../models/common/CommonTypes.sol';
import './IRentalityGeoService.sol';
import './RentalityLocationVerifier.sol';
import '../../upgradeable/UUPSOwnable.sol';

interface IRentalityGeoAccess {
  function isAdmin(address user) external view returns (bool);
}

contract RentalityGeoService is IRentalityGeoService, UUPSOwnable {
  IRentalityGeoAccess public userAccess;
  RentalityLocationVerifier private verifier;
  mapping(bytes32 => LocationInfo) public locationDictionary;
  mapping(uint256 => bool) private carIdToCoordinateValidity;

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress, address locationVerifier) public initializer {
    __Ownable_init();
    userAccess = IRentalityGeoAccess(userAccessAddress);
    verifier = RentalityLocationVerifier(locationVerifier);
  }

  function createLocationInfo(LocationInfo memory info) public returns (bytes32) {
    bytes32 hash = hashLocationInfo(info);
    locationDictionary[hash] = info;
    return hash;
  }

  function executeRequest(
    string memory addr,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory,
    uint256 carId
  ) external returns (bytes32) {
    LocationInfo memory info = LocationInfo({
      userAddress: addr,
      country: '',
      state: '',
      city: '',
      latitude: locationLatitude,
      longitude: locationLongitude,
      timeZoneId: ''
    });

    carIdToCoordinateValidity[carId] =
      bytes(locationLatitude).length != 0 && bytes(locationLongitude).length != 0;

    return createLocationInfo(info);
  }

  function parseGeoResponse(uint256) external pure {}

  function getCarCoordinateValidity(uint256 carId) external view returns (bool) {
    return carIdToCoordinateValidity[carId];
  }

  function createSignedLocationInfo(SignedLocationInfo memory info) public returns (bytes32) {
    if (info.signature.length == 0) {
      return bytes32('');
    }
    verifySignedLocationInfo(info);
    return createLocationInfo(info.locationInfo);
  }

  function hashLocationInfo(LocationInfo memory info) public pure returns (bytes32) {
    if (bytes(info.longitude).length == 0) {
      return bytes32('');
    }
    return keccak256(abi.encode(info.country, info.state, info.city, info.latitude, info.longitude, info.timeZoneId));
  }

  function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) public view {
    verifier.verifySignedLocationInfo(locationInfo);
  }

  function getLocationInfo(bytes32 hash) public view returns (LocationInfo memory) {
    return locationDictionary[hash];
  }

  function getCarCity(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].city;
  }

  function getCarState(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].state;
  }

  function getCarCountry(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].country;
  }

  function getCarLocationLatitude(bytes32 hash) external view returns (string memory) {
    return locationDictionary[hash].latitude;
  }

  function getCarLocationLongitude(bytes32 hash) external view returns (string memory) {
    return locationDictionary[hash].longitude;
  }

  function getCarTimeZoneId(bytes32 hash) public view returns (string memory) {
    return locationDictionary[hash].timeZoneId;
  }

  function setLocationVerifier(address locationVerifier) public {
    require(userAccess.isAdmin(msg.sender) || userAccess.isAdmin(tx.origin), 'only admin');
    verifier = RentalityLocationVerifier(locationVerifier);
  }

  function getVerifier() public view returns (RentalityLocationVerifier) {
    return verifier;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityGeoAccess(userAccessAddress);
  }
}
