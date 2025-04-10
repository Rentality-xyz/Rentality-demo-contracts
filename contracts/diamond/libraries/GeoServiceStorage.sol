// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import {RentalityLocationVerifier} from "../../features/RentalityLocationVerifier.sol";
import { LibDiamond } from "./LibDiamond.sol";

library GeoServiceStorage { 
    struct GeoServiceFaucetStorage {
        RentalityLocationVerifier locationVerifier;
        mapping(bytes32 => Schemas.LocationInfo) locationDictionary;

    }

    function accessStorage() internal pure returns (GeoServiceFaucetStorage storage ds) {
        bytes32 position = LibDiamond.GEO_SERVICE_STORAGE_POSITION;
        assembly { ds.slot := position }
    }

   
  /// @notice Retrieves the city of geolocation for a car.
  /// @return city The city name.
  function getCarCity(bytes32 hash) internal view returns (string memory) {
  GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].city;
  }

  /// @notice Retrieves the state of geolocation for a car.
  /// @return state The state name.
  function getCarState(bytes32 hash) internal view returns (string memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].state;
  }

  /// @notice Retrieves the country of geolocation for a car.
  /// @return country The country name.
  function getCarCountry(bytes32 hash) internal view returns (string memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].country;
  }

  /// @notice Retrieves the latitude of geolocation for a car.
  /// @return locationLat The latitude.
  function getCarLocationLatitude(bytes32 hash) internal view returns (string memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].latitude;
  }

  /// @notice Retrieves the longitude of geolocation for a car.
  /// @return locationLng The longitude.
  function getCarLocationLongitude(bytes32 hash) internal view returns (string memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].longitude;
  }

  /// @notice Retrieves the time zone information associated with a specific car.
  /// @return timeZone A string representing the time zone of the specified car's geolocation data.
  function getCarTimeZoneId(bytes32 hash) internal view returns (string memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash].timeZoneId;
  }

  function createLocationInfo(Schemas.LocationInfo memory info) internal returns (bytes32) {
    GeoServiceFaucetStorage storage s = accessStorage();
    bytes32 hash = hashLocationInfo(info);
    s.locationDictionary[hash] = info;

    return hash;
  }
  function createSignedLocationInfo(Schemas.SignedLocationInfo memory info) internal returns (bytes32) {
    if (info.signature.length == 0) {
      return bytes32('');
    }
    verifySignedLocationInfo(info);
    return createLocationInfo(info.locationInfo);
  }

  function hashLocationInfo(Schemas.LocationInfo memory info) internal pure returns (bytes32) {
    if (bytes(info.longitude).length == 0) {
      return bytes32('');
    }
    bytes32 hash = keccak256(
      abi.encode(info.country, info.state, info.city, info.latitude, info.longitude, info.timeZoneId)
    );

    return hash;
  }

  function getLocationInfo(bytes32 hash) internal view returns (Schemas.LocationInfo memory) {
    GeoServiceFaucetStorage storage s = accessStorage();
    return s.locationDictionary[hash];
  }

  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) internal view {
    GeoServiceFaucetStorage storage s = accessStorage();
    s.locationVerifier.verifySignedLocationInfo(locationInfo);
  }
  function setVerifier(address verifier) internal {
    GeoServiceFaucetStorage storage s = accessStorage();
    s.locationVerifier = RentalityLocationVerifier(verifier);
  }

}