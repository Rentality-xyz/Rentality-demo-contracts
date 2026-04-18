// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface ICarViewGatewayFacet {
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);
  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.AvailableCarDTO memory);
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (Schemas.SearchCarsWithDistanceDTO memory);
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfoWithInsurance memory);
  function getCarDetails(uint256 carId) external view returns (Schemas.CarDetails memory);
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);
  function getCarMetadataURI(uint256 carId) external view returns (string memory);
  function getTotalCarsAmount() external view returns (uint256);
  function getDeliveryData(uint256 carId) external view returns (Schemas.DeliveryData memory);
  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory);
}
