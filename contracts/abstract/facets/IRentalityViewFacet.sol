// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityViewFacet {
  function getAvailableCarsForUser(address user) external view returns (Schemas.CarInfo[] memory);
  function checkCarAvailabilityWithDelivery(
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo
  ) external view returns (Schemas.AvailableCarDTO memory);
  function searchAvailableCarsWithDelivery(
    uint64 startDateTime,
    uint64 endDateTime,
    Schemas.SearchCarParams memory searchParams,
    Schemas.LocationInfo memory pickUpInfo,
    Schemas.LocationInfo memory returnInfo,
    uint from,
    uint to
  ) external view returns (Schemas.SearchCarsWithDistanceDTO memory);
  function getMyCars() external view returns (Schemas.CarInfoDTO[] memory);
  function getCarInfoById(uint256 carId) external view returns (Schemas.CarInfoWithInsurance memory);
  function getCarDetails(uint carId) external view returns (Schemas.CarDetails memory);
  function getMyClaimsAs(bool host) external view returns (Schemas.FullClaimInfo[] memory);
  function getClaim(uint256 claimId) external view returns (Schemas.ClaimV2 memory);
  function getCarsOfHost(address host) external view returns (Schemas.PublicHostCarDTO[] memory);
  function getDiscount(address user) external view returns (Schemas.BaseDiscount memory);
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    string memory promo
  ) external view returns (Schemas.CalculatePaymentsDTO memory);
  function getDeliveryData(uint carId) external view returns (Schemas.DeliveryData memory);
  function getUserDeliveryPrices(address user) external view returns (Schemas.DeliveryPrices memory);
  function getKycCommission() external view returns (uint64);
  function isKycCommissionPaid(address user) external view returns (bool);
  function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory);
  function getInsurancesBy(bool host) external view returns (Schemas.InsuranceDTO[] memory);
  function calculateClaimValue(uint claimId) external view returns (uint);
  function getMyInsurancesAsGuest() external view returns (Schemas.InsuranceInfo[] memory);
  function getAvailableCurrency() external view returns (Schemas.AllowedCurrencyDTO[] memory);
}
