pragma solidity ^0.8.20;

import '../../../../models/investment/RentalInvestmentTypes.sol';

interface IRentalityInvestmentSender {
  function quoteInvest(uint, uint investId, uint amount) external view returns (uint);
  function claimAllMy(uint) external;
  function quoteClaimAllMy(uint) external view returns (uint);
  function createCarInvestment(RentalCarInvestment memory car, string memory name_, address currency) external;
  function quoteCreateCarInvestment(RentalCarInvestment memory car, string memory name_, address currency) external view returns (uint);
  function claimAndCreatePool(uint carId, RentalInvestmentCarRequest memory createCarRequest) external;
  function quoteClaimAndCreatePool(uint carId, RentalInvestmentCarRequest memory createCarRequest) external view returns (uint);
  function changeListingStatus(uint) external;
  function quoteChangeListingStatus(uint) external view returns (uint);
}
