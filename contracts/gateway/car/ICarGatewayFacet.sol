// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface ICarGatewayFacet {
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint newTokenId);
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfoWithInsurance memory);
  function getCarDetails(uint256 carId) external view returns (Schemas.CarDetails memory);
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);
  function getCarMetadataURI(uint256 carId) external view returns (string memory);
  function getTotalCarsAmount() external view returns (uint256);
}
