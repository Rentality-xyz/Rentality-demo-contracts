pragma solidity ^0.8.20;

import '../../../../models/investment/InvestmentTypes.sol';

interface IRentalityInvestmentSender {
  function quoteInvest(uint, uint investId, uint amount) external view returns (uint);
  function claimAllMy(uint) external;
  function quoteClaimAllMy(uint) external view returns (uint);
  function createCarInvestment(CarInvestment memory car, string memory name_, address currency) external;
  function quoteCreateCarInvestment(CarInvestment memory car, string memory name_, address currency) external view returns (uint);
  function claimAndCreatePool(uint carId, InvestmentCarRequest memory createCarRequest) external;
  function quoteClaimAndCreatePool(uint carId, InvestmentCarRequest memory createCarRequest) external view returns (uint);
  function changeListingStatus(uint) external;
  function quoteChangeListingStatus(uint) external view returns (uint);
}
