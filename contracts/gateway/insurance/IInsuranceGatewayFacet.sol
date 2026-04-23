// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/referral/ReferralTypes.sol';
import '../../models/insurance/InsuranceTypes.sol';

interface IInsuranceGatewayFacet {
  function getInsurancesBy(bool host) external view returns (InsuranceDTO[] memory);
  function getMyInsurancesAsGuest() external view returns (InsuranceInfo[] memory);
  function getGuestInsurance(address guest) external view returns (InsuranceInfo[] memory);
  function getHostInsuranceClaims() external view returns (FullReferralClaimInfo[] memory claimInfos);
  function getHostInsuranceRule(address host) external view returns (HostInsuranceRuleDTO memory insuranceRules);
  function getAllInsuranceRules() external view returns (HostInsuranceRuleDTO[] memory insuranceRules);
  function getHostInsuranceBalance() external view returns (uint);
  function saveGuestInsurance(SaveInsuranceRequest memory insuranceInfo) external;
  function saveTripInsuranceInfo(uint tripId, SaveInsuranceRequest memory insuranceInfo) external;
  function setHostInsurance(uint insuranceId) external;
}
