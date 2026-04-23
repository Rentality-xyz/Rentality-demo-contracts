// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../infrastructure/services/AiDamageTypes.sol';
import '../../models/claim/RentalClaimTypes.sol';

interface IClaimGatewayFacet {
  function getMyClaimsAs(bool host) external view returns (FullClaimInfo[] memory);
  function getClaim(uint256 claimId) external view returns (RentalClaimInfoV2 memory);
  function calculateClaimValue(uint256 claimId) external view returns (uint256);
  function getAiDamageAnalyzeCaseRequest(uint tripId, CaseType caseType)
    external
    view
    returns (AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest);
  function createClaim(CreateClaimRequest memory request, bool isInsuranceClaim) external;
  function rejectClaim(uint256 claimId) external;
  function payClaim(uint256 claimId) external payable;
}
