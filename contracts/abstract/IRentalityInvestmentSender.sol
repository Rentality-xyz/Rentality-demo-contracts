// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../Schemas.sol';

interface IRentalityInvestmentSender {

    
  function quoteInvest(uint,uint investId, uint amount) external view returns (uint);
  function claimAllMy(uint) external;
  function quoteClaimAllMy(uint) external view returns (uint);
  function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, address currency) external;
  function quoteCreateCarInvestment(Schemas.CarInvestment memory car, string memory name_, address currency) external view returns (uint);
  function claimAndCreatePool(uint carId,Schemas.CreateCarRequest memory createCarRequest) external;
  function quoteClaimAndCreatePool(uint carId,Schemas.CreateCarRequest memory createCarRequest) external view returns (uint);
  
  function changeListingStatus(uint) external;
  function quoteChangeListingStatus(uint) external view returns (uint);
}