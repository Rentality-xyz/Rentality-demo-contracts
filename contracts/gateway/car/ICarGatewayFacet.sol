// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../models/car/CarTypes.sol';
import '../../models/common/CommonTypes.sol';

interface ICarGatewayFacet {
  function addCar(CarGatewayTypes.GatewayCreateCarRequest memory request) external returns (uint newTokenId);
  function updateCarInfoWithLocation(
    CarGatewayTypes.UpdateCarInfoRequest memory request,
    SignedLocationInfo memory location
  ) external;
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function saveDimoTokenIds(uint[] memory dimoTokenIds, uint[] memory carIds) external;
}
