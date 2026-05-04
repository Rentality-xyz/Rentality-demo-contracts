// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../models/car/CarTypes.sol';
import '../../models/common/CommonTypes.sol';

interface ICarGatewayFacet {
  function addCar(
    CreateCarRequest memory request,
    uint256 insurancePriceInUsdCents,
    bool insuranceRequired,
    uint256 dimoTokenId,
    bytes memory signedDimoTokenId
  ) external returns (uint newTokenId);
  function updateCarInfoWithLocation(
    uint256 carId,
    UpdateCarRequest memory request,
    SignedLocationInfo memory location,
    uint256 insurancePriceInUsdCents,
    bool insuranceRequired
  ) external;
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) external;
  function getAvailableCarsForUser(address user) external view returns (CarInfo[] memory);
  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo
  ) external view returns (AvailableCarInfo memory);
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    CarSearchParams memory searchParams,
    LocationInfo memory pickUpInfo,
    LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (SearchCarsWithDistanceInfo memory);
  function getCarsOfHost(address host) external view returns (PublicHostCarInfo[] memory);
  function getUniqCarsBrand() external view returns (string[] memory brandsArray);
  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray);
  function getFilterInfo(uint64 duration) external view returns (CarFilterInfo memory);
  function getAllCars(uint page, uint itemsPerPage) external view returns (AllCarsInfo memory allCars);
  function getDimoVehicles() external view returns (uint[] memory);
  function getCarMetadataURI(uint256 carId) external view returns (string memory);
  function getTotalCarsAmount() external view returns (uint256);
  function getMyCars() external view returns (CarInfoDTO[] memory);
  function getCarInfoById(uint256 carId) external view returns (CarInfoWithInsurance memory);
  function getCarDetails(uint256 carId) external view returns (CarDetails memory);
  function getDeliveryData(uint256 carId) external view returns (CarGatewayTypes.DeliveryData memory);
  function getUserDeliveryPrices(address user) external view returns (CarGatewayTypes.GatewayDeliveryPrices memory);
}
