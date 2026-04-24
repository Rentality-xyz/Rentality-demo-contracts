// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/car/CarTypes.sol';
import '../../models/common/CommonTypes.sol';

interface ICarViewGatewayFacet {
  function getAvailableCarsForUser(address user) external view returns (CarGatewayTypes.GatewayCarInfo[] memory);
  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo
  ) external view returns (CarGatewayTypes.AvailableCarDTO memory);
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    CarGatewayTypes.SearchCarParams memory searchParams,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (CarGatewayTypes.SearchCarsWithDistanceDTO memory);
  function getCarsOfHost(address host) external view returns (CarGatewayTypes.PublicHostCarDTO[] memory);
  function getUniqCarsBrand() external view returns (string[] memory brandsArray);
  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray);
  function getFilterInfo(uint64 duration) external view returns (CarGatewayTypes.FilterInfoDTO memory);
  function getAllCars(uint page, uint itemsPerPage) external view returns (CarGatewayTypes.AllCarsDTO memory allCars);
  function getDimoVehicles() external view returns (uint[] memory);
  function getCarMetadataURI(uint256 carId) external view returns (string memory);
  function getTotalCarsAmount() external view returns (uint256);
}
