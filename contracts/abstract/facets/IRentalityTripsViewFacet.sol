// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityTripsViewFacet {
  function getTripContactInfo(uint256 tripId) external view returns (string memory guestPhoneNumber, string memory hostPhoneNumber);
  function getTrip(uint256 tripId) external view returns (Schemas.TripDTO memory);
  function getTripsAs(bool host) external view returns (Schemas.TripDTO[] memory);
  function calculateKycCommission(address currency) external view returns (uint);
  function checkPromo(string memory promo, uint startDateTime, uint endDateTime) external view returns (Schemas.CheckPromoDTO memory);
  function getUniqCarsBrand() external view returns (string[] memory brandsArray);
  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray);
  function getAvaibleCurrencies() external view returns (Schemas.Currency[] memory);
  function getFilterInfo(uint64 duration) external view returns (Schemas.FilterInfoDTO memory);
  function getAiDamageAnalyzeCaseRequest(uint tripId, Schemas.CaseType caseType) external view returns (Schemas.AiDamageAnalyzeCaseRequestDTO memory aiDamageAnalyzeCaseRequest);
  function getDimoVehicles() external view returns (uint[] memory);
  function getUserCurrency(address user) external view returns (Schemas.UserCurrencyDTO memory userCurrency);
  function getCarMetadataURI(uint256 carId) external view returns (string memory);
  function getTotalCarsAmount() external view returns (uint);
  function getGuestInsurance(address guest) external view returns (Schemas.InsuranceInfo[] memory);
  function getTaxesInfoById(uint taxId) external view returns (Schemas.TaxesInfoDTO memory);
  function getPlatformInfo() external view returns (Schemas.PlatformInfoDTO memory);
  function getHostInsuranceClaims() external view returns (Schemas.FullClaimInfo[] memory claimInfos);
  function getHostInsuranceRule(address host) external view returns (Schemas.HostInsuranceRuleDTO memory insuranceRules);
  function getAllInsuranceRules() external view returns (Schemas.HostInsuranceRuleDTO[] memory insuranceRules);
  function getHostInsuranceBalance() external view returns (uint);
  function getChatInfoFor(bool host) external view returns (Schemas.ChatInfo[] memory);
}
