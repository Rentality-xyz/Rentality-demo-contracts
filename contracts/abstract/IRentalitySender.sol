// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../Schemas.sol';
import './facets/IRentalityPlatformFacet.sol';
import './facets/IRentalityPlatformHelperFacet.sol';
import './IRentalityInvestmentSender.sol';
import './IRentalityRefferalSender.sol';

interface IRentalitySender {
  function quote(uint amount, uint gasLimit, bytes memory data) external view returns (uint);
  function send(uint amount,uint gasLimit, bytes memory encodetData) external payable;

}
