// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityReferralProgramFacet {
  function addressToPoints(address user) external view returns (uint256);
  function referralHashV2(address user) external view returns (bytes4);
  function getCarDailyClaimedTime(uint carId) external view returns (uint64);
  function getMyStartDiscount(address user) external view returns (Schemas.RefferalDiscount memory);
  function getReadyToClaim(address user) external view returns (Schemas.ReadyToClaimDTO memory readyToClaimDTO);
  function getReadyToClaimFromRefferalHash(address) external view returns (Schemas.RefferalHashDTO memory refferalHashDTO);
  function getRefferalPointsInfo() external view returns (Schemas.AllRefferalInfoDTO memory allRefferalInfoDTO);
  function getPointsHistory(address user) external view returns (Schemas.RefferalHistory[] memory);
  function getMyRefferalInfo() external view returns (Schemas.MyRefferalInfoDTO memory myRefferalInfoDTO);
  function claimPoints(address user) external;
  function claimRefferalPoints(address) external;
  function hashExists(bytes32 referralHash) external view returns (bool);
}
