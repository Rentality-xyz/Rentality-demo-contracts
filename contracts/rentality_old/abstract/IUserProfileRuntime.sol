// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IRentalityAccessControl.sol';

interface IUserProfileRuntime is IRentalityAccessControl {
  function grantHostRole(address user) external;

  function isSignatureManager(address user) external view returns (bool);

  function isInvestorManager(address user) external view returns (bool);

  function isCommissionPaidForUser(address user) external view returns (bool);

  function payCommission(address user) external;
}
