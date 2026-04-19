// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface IClaimGatewayFacet {
  function getMyClaimsAs(bool host) external view returns (Schemas.FullClaimInfo[] memory);
  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory);
  function calculateClaimValue(uint256 claimId) external view returns (uint256);
  function getAiDamageAnalyzeCaseRequest(uint tripId, Schemas.CaseType caseType)
    external
    view
    returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest);
}
