// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface IInsuranceGatewayFacet {
  function getInsurancesBy(bool host) external view returns (Schemas.InsuranceDTO[] memory);
  function getMyInsurancesAsGuest() external view returns (Schemas.InsuranceInfo[] memory);
  function getGuestInsurance(address guest) external view returns (Schemas.InsuranceInfo[] memory);
  function getHostInsuranceClaims() external view returns (Schemas.FullClaimInfo[] memory claimInfos);
  function getHostInsuranceRule(address host) external view returns (Schemas.HostInsuranceRuleDTO memory insuranceRules);
  function getAllInsuranceRules() external view returns (Schemas.HostInsuranceRuleDTO[] memory insuranceRules);
  function getHostInsuranceBalance() external view returns (uint);
  function saveGuestInsurance(Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function saveTripInsuranceInfo(uint tripId, Schemas.SaveInsuranceRequest memory insuranceInfo) external;
  function setHostInsurance(uint insuranceId) external;
}
