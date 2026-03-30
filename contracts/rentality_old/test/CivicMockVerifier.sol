// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import {IGatewayTokenVerifier} from '@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol';

contract CivicMockVerifier is IGatewayTokenVerifier {
  function verifyToken(address, uint256) external pure returns (bool) {
    return true;
  }

  function verifyToken(uint256) external pure returns (bool) {
    return true;
  }
}
