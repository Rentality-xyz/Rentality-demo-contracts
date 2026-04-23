// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/base/insurance/InsuranceTypes.sol';
import '../../models/claim/RentalClaimTypes.sol';
import '../../models/insurance/RentalInsuranceTypes.sol';

interface IInsuranceGatewayFacet {
  function getInsurancesBy(bool host) external view returns (RentalInsuranceDTO[] memory);
  function getMyInsurancesAsGuest() external view returns (InsuranceInfo[] memory);
  function getGuestInsurance(address guest) external view returns (InsuranceInfo[] memory);
  function getHostInsuranceClaims() external view returns (FullClaimInfo[] memory claimInfos);
  function getHostInsuranceRule(address host) external view returns (RentalHostInsuranceRuleDTO memory insuranceRules);
  function getAllInsuranceRules() external view returns (RentalHostInsuranceRuleDTO[] memory insuranceRules);
  function getHostInsuranceBalance() external view returns (uint);
  function saveGuestInsurance(RentalSaveInsuranceRequest memory insuranceInfo) external;
  function saveTripInsuranceInfo(uint tripId, RentalSaveInsuranceRequest memory insuranceInfo) external;
  function setHostInsurance(uint insuranceId) external;
}
