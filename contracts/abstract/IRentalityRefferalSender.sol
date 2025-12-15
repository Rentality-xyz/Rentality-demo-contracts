  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../Schemas.sol';
interface IRentalityRefferalSender {
  function claimPoints(address user) external;
  function quoteClaimPoints(address user) external view returns (uint);
  function claimRefferalPoints(address) external;
  function quoteClaimRefferalPoints(address) external view returns (uint);
}