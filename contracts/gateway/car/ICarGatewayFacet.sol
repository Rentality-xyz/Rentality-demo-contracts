// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface ICarGatewayFacet {
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint newTokenId);
  function updateCarInfoWithLocation(
    Schemas.UpdateCarInfoRequest memory request,
    Schemas.SignedLocationInfo memory location
  ) external;
  function addUserDeliveryPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
}
