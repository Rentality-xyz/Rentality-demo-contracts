// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/Schemas.sol';

interface ITripSource {
  function getTrip(uint256 tripId) external view returns (Schemas.Trip memory);
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getCarTrips(uint256 carId) external view returns (uint256[] memory);
  function getTripsByUser(address user) external view returns (uint256[] memory);
  function totalTripCount() external view returns (uint256);
  function completedByAdmin(uint256 tripId) external view returns (bool);
}
