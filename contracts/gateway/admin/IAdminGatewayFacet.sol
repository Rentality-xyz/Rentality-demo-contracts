// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/Schemas.sol';
import '../../rentality_old/abstract/IRentalityAdminGateway.sol';

interface IAdminGatewayFacet is IRentalityAdminGateway {
  function getInvestmentAddress() external view returns (address investmentAddress);
  function updateNotificationService(address contractAddress) external;
  function updatePromoData(string memory prefix, uint discount) external;
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxes(uint taxesId, uint64 daysOfTrip, uint64 value) external view returns (uint64);
  function calculateTaxesDTO(uint taxesId, uint64 daysOfTrip, uint64 value)
    external
    view
    returns (uint64 totalTax, Schemas.TaxValue[] memory taxValues);
  function setPlatformFee(uint value) external;
  function setKycCommission(uint value) external;
  function getAllTrips(Schemas.TripFilter memory filter, uint page, uint itemsPerPage)
    external
    view
    returns (Schemas.AllTripsDTO memory allTrips);
  function manageRole(Schemas.Role role, address user, bool grant) external;
  function getAllCars(uint page, uint itemsPerPage) external view returns (Schemas.AllCarsDTO memory allCars);
  function manageRefferalBonusAccrual(
    Schemas.RefferalAccrualType accrualType,
    Schemas.RefferalProgram program,
    int points,
    int pointsWithReffHash
  ) external;
  function manageRefferalHashPoints(Schemas.RefferalProgram program, uint points) external;
  function manageRefferalDiscount(Schemas.RefferalProgram program, Schemas.Tear tear, uint points, uint percents)
    external;
  function manageTearInfo(Schemas.Tear tear, uint from, uint to) external;
  function getPlatformUsersInfo(uint page, uint itemsPerPage)
    external
    view
    returns (Schemas.AdminKYCInfosDTO memory result);
  function getAllClaimTypes(bool byHost) external view returns (Schemas.ClaimTypeV2[] memory claimTypes);
  function addClaimType(string memory name, Schemas.ClaimCreator creator) external;
  function removeClaimType(uint8 claimType) external;
  function setDefaultCurrencyType(address currency) external;
  function setDefaultPrices(uint64 underTwentyFiveMilesInUsdCents, uint64 aboveTwentyFiveMilesInUsdCents) external;
  function setDefaultDiscount(Schemas.BaseDiscount memory newDiscounts) external;
  function addTaxes(string memory location, Schemas.TaxesLocationType locationType, Schemas.TaxValue[] memory taxes)
    external;
}
