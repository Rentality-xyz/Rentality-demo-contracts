// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './RentalityCurrencyType.sol';

contract RentalityETHConvertor is ARentalityUpgradableCurrencyType {
  function tokenDecimals() public pure override returns (uint8) {
    return 18;
  }
}
