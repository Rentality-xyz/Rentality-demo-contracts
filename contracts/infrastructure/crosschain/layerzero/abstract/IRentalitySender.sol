pragma solidity ^0.8.20;

interface IRentalitySender {
  function quote(uint amount, uint gasLimit, bytes memory data) external view returns (uint);
  function send(uint amount, uint gasLimit, bytes memory encodetData) external payable;
}
