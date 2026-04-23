// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/car/CarTypes.sol';

interface ICarViewGatewayFacet1 {
  function getMyCars() external view returns (CarGatewayTypes.GatewayCarInfoDTO[] memory);
  function getCarInfoById(uint256 carId) external view returns (CarGatewayTypes.GatewayCarInfoWithInsurance memory);
  function getCarDetails(uint256 carId) external view returns (CarGatewayTypes.GatewayCarDetails memory);
  function getDeliveryData(uint256 carId) external view returns (CarGatewayTypes.DeliveryData memory);
  function getUserDeliveryPrices(address user) external view returns (CarGatewayTypes.GatewayDeliveryPrices memory);
}
