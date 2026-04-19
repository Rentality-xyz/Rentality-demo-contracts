// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable as OZInitializable} from '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';
import '../../rentality_old/abstract/ARentalityContext.sol';
import '../../rentality_old/Schemas.sol';
import '../../models/insurance/RentalInsuranceQueryFacet1.sol';
import '../../models/insurance/RentalInsuranceQueryFacet2.sol';
import './IInsuranceGatewayFacet.sol';

interface IInsuranceGatewayUserAccess {
  function isRentalityPlatform(address user) external view returns (bool);
}

contract InsuranceGatewayFacet is UUPSOwnable, ARentalityContext, IInsuranceGatewayFacet {
  RentalInsuranceQueryFacet1 public insuranceQueryFacet1;
  RentalInsuranceQueryFacet2 public insuranceQueryFacet2;
  IInsuranceGatewayUserAccess public userAccess;

  constructor() {
    _disableInitializers();
  }

  function initialize(
    address insuranceQueryFacet1Address,
    address insuranceQueryFacet2Address,
    address userServiceAddress
  ) public initializer {
    __Ownable_init();
    insuranceQueryFacet1 = RentalInsuranceQueryFacet1(insuranceQueryFacet1Address);
    insuranceQueryFacet2 = RentalInsuranceQueryFacet2(insuranceQueryFacet2Address);
    userAccess = IInsuranceGatewayUserAccess(userServiceAddress);
  }

  function updateServiceAddresses(
    address insuranceQueryFacet1Address,
    address insuranceQueryFacet2Address,
    address userServiceAddress
  ) external onlyOwner {
    insuranceQueryFacet1 = RentalInsuranceQueryFacet1(insuranceQueryFacet1Address);
    insuranceQueryFacet2 = RentalInsuranceQueryFacet2(insuranceQueryFacet2Address);
    userAccess = IInsuranceGatewayUserAccess(userServiceAddress);
  }

  function getInsurancesBy(bool host) external view returns (Schemas.InsuranceDTO[] memory) {
    return insuranceQueryFacet1.getInsurancesBy(host, _msgGatewaySender());
  }

  function getMyInsurancesAsGuest() external view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceQueryFacet1.getMyInsurancesAsGuest(_msgGatewaySender());
  }

  function getGuestInsurance(address guest) external view returns (Schemas.InsuranceInfo[] memory) {
    return insuranceQueryFacet2.getGuestInsurance(guest);
  }

  function getHostInsuranceClaims() external view returns (Schemas.FullClaimInfo[] memory claimInfos) {
    return insuranceQueryFacet2.getHostInsuranceClaims();
  }

  function getHostInsuranceRule(address host) external view returns (Schemas.HostInsuranceRuleDTO memory insuranceRules) {
    return insuranceQueryFacet2.getHostInsuranceRule(host);
  }

  function getAllInsuranceRules() external view returns (Schemas.HostInsuranceRuleDTO[] memory insuranceRules) {
    return insuranceQueryFacet2.getAllInsuranceRules();
  }

  function getHostInsuranceBalance() external view returns (uint) {
    return insuranceQueryFacet2.getHostInsuranceBalance();
  }

  function isTrustedForwarder(address forwarder) internal view override returns (bool) {
    return address(userAccess) != address(0) && userAccess.isRentalityPlatform(forwarder);
  }
}
