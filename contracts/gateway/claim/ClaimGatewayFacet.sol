// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';
import '../../rentality_old/Schemas.sol';
import '../../models/claim/RentalClaimQuery.sol';
import './IClaimGatewayFacet.sol';

interface IClaimGatewayUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

contract ClaimGatewayFacet is UUPSOwnable, ARentalityContext, IClaimGatewayFacet {
  RentalClaimQuery public claimQuery;
  IClaimGatewayUserAccess public userAccess;

  constructor() {
    _disableInitializers();
  }

  function initialize(address claimQueryAddress, address userServiceAddress) public initializer {
    __Ownable_init();
    claimQuery = RentalClaimQuery(claimQueryAddress);
    userAccess = IClaimGatewayUserAccess(userServiceAddress);
  }

  function updateServiceAddresses(address claimQueryAddress, address userServiceAddress) external onlyOwner {
    claimQuery = RentalClaimQuery(claimQueryAddress);
    userAccess = IClaimGatewayUserAccess(userServiceAddress);
  }

  function getMyClaimsAs(bool host) external view returns (Schemas.FullClaimInfo[] memory) {
    return claimQuery.getMyClaimsAs(host, _msgGatewaySender());
  }

  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory) {
    return claimQuery.getClaim(claimId);
  }

  function calculateClaimValue(uint256 claimId) external view returns (uint256) {
    return claimQuery.calculateClaimValue(claimId);
  }

  function getAiDamageAnalyzeCaseRequest(uint tripId, Schemas.CaseType caseType)
    external
    view
    returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest)
  {
    return claimQuery.getAiDamageAnalyzeCaseRequest(tripId, caseType, _msgGatewaySender());
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }
}
