// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../infrastructure/services/AiDamageTypes.sol';
import '../ARentalityContext.sol';
import '../../models/claim/RentalClaimQuery.sol';
import '../../models/claim/RentalClaimMain.sol';
import '../../models/claim/RentalClaimTypes.sol';
import './IClaimGatewayFacet.sol';

interface IClaimGatewayUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

contract ClaimGatewayFacet is UUPSOwnable, ARentalityContext, IClaimGatewayFacet {
  RentalClaimQuery public claimQuery;
  RentalClaimMain public claimMain;
  IClaimGatewayUserAccess public userAccess;

  constructor() {
    _disableInitializers();
  }

  function initialize(address claimQueryAddress, address claimMainAddress, address userServiceAddress) public initializer {
    __Ownable_init();
    claimQuery = RentalClaimQuery(claimQueryAddress);
    claimMain = RentalClaimMain(claimMainAddress);
    userAccess = IClaimGatewayUserAccess(userServiceAddress);
  }

  function updateServiceAddresses(address claimQueryAddress, address claimMainAddress, address userServiceAddress) external onlyOwner {
    claimQuery = RentalClaimQuery(claimQueryAddress);
    claimMain = RentalClaimMain(claimMainAddress);
    userAccess = IClaimGatewayUserAccess(userServiceAddress);
  }

  function getMyClaimsAs(bool host) external view returns (FullClaimInfo[] memory) {
    return claimQuery.getMyClaimsAs(host, _msgGatewaySender());
  }

  function getClaim(uint256 claimId) external view returns (RentalClaimInfoV2 memory) {
    return claimQuery.getClaim(claimId);
  }

  function calculateClaimValue(uint256 claimId) external view returns (uint256) {
    return claimQuery.calculateClaimValue(claimId);
  }

  function getAiDamageAnalyzeCaseRequest(uint tripId, CaseType caseType)
    external
    view
    returns (AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest)
  {
    return claimQuery.getAiDamageAnalyzeCaseRequest(tripId, caseType, _msgGatewaySender());
  }

  function createClaim(CreateClaimRequest memory request, bool isInsuranceClaim) external {
    claimMain.createClaim(request, isInsuranceClaim, _msgGatewaySender());
  }

  function rejectClaim(uint256 claimId) external {
    claimMain.rejectClaim(claimId, _msgGatewaySender());
  }

  function payClaim(uint256 claimId) external payable {
    claimMain.payClaim{value: msg.value}(claimId, _msgGatewaySender());
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }
}
