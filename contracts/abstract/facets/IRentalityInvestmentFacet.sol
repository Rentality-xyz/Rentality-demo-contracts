// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../Schemas.sol';

interface IRentalityInvestmentFacet {
  function invest(uint investId, uint amount) external payable;
  function claimAllMy(uint) external;
  function getPaymentsInfo() external view returns (Schemas.PaymentInfo[] memory);
  function getAllInvestments() external view returns (Schemas.InvestmentDTO[] memory);
  function createCarInvestment(Schemas.CarInvestment memory car, string memory name_, address currency) external;
  function claimAndCreatePool(uint carId,Schemas.CreateCarRequest memory createCarRequest) external;
  function changeListingStatus(uint) external;
}
