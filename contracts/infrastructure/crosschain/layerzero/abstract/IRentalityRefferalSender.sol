pragma solidity ^0.8.20;

interface IRentalityRefferalSender {
  function claimPoints(address user) external;
  function quoteClaimPoints(address user) external view returns (uint);
  function claimRefferalPoints(address user) external;
  function quoteClaimRefferalPoints(address user) external view returns (uint);
}
