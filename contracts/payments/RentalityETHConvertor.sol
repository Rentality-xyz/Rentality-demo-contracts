// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import './RentalityCurrencyType.sol';

contract RentalityETHConvertor is ARentalityUpgradableCurrencyType {

   function tokenDecimals() public pure override returns (uint8) {
    return 18;
  }
}
