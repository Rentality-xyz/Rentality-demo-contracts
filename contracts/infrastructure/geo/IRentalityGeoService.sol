// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/Schemas.sol';

/// @title IRentalityGeoService
/// @notice Shared interface for Rentality geolocation services.
interface IRentalityGeoService {
  function executeRequest(
    string memory addr,
    string memory locationLatitude,
    string memory locationLongitude,
    string memory key,
    uint256 carId
  ) external returns (bytes32);

  function parseGeoResponse(uint256 carId) external;

  function getCarCoordinateValidity(uint256 carId) external view returns (bool);

  function getCarCity(bytes32 hash) external view returns (string memory);

  function getCarState(bytes32 hash) external view returns (string memory);

  function getCarCountry(bytes32 hash) external view returns (string memory);

  function getCarTimeZoneId(bytes32 hash) external view returns (string memory);

  function getCarLocationLatitude(bytes32 hash) external view returns (string memory);

  function getCarLocationLongitude(bytes32 hash) external view returns (string memory);

  function createLocationInfo(Schemas.LocationInfo memory info) external returns (bytes32);

  function createSignedLocationInfo(Schemas.SignedLocationInfo memory info) external returns (bytes32);

  function hashLocationInfo(Schemas.LocationInfo memory info) external returns (bytes32);

  function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);

  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory signed) external view;
}
