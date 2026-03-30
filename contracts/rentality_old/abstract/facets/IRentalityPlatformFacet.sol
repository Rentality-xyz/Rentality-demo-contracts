// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityPlatformFacet {
  function createTripRequestWithDelivery(
    Schemas.CreateTripRequestWithDelivery memory request,
    string memory promo
  ) external payable;
  function approveTripRequest(uint256 tripId) external;
  function rejectTripRequest(uint256 tripId) external;
  function confirmCheckOut(uint256 tripId) external;
  function finishTrip(uint256 tripId) external;
  function createClaim(Schemas.CreateClaimRequest memory request, bool isInsuranceClaim) external;
  function rejectClaim(uint256 claimId) external;
  function payClaim(uint256 claimId) external payable;
  function checkInByHost(
    uint256 tripId,
    uint64[] memory panelParams,
    string memory insuranceCompany,
    string memory insuranceNumber
  ) external;
  function checkInByGuest(uint256 tripId, uint64[] memory panelParams) external;
  function checkOutByGuest(uint256 tripId, uint64[] memory panelParams) external;
  function checkOutByHost(uint256 tripId, uint64[] memory panelParams) external;
  function addCar(Schemas.CreateCarRequest memory request) external returns (uint newTokenId);
}
