// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGatewayTokenVerifier} from '@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol';

contract CivicMockVerifier is IGatewayTokenVerifier {
  bool public verifyResult = true;

  function setVerifyResult(bool value) external {
    verifyResult = value;
  }

  function verifyToken(address, uint256) external view override returns (bool) {
    return verifyResult;
  }

  function verifyToken(uint256) external view override returns (bool) {
    return verifyResult;
  }
}
