// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../proxy/UUPSAccess.sol';
abstract contract ARentalityRefferal {
  function getUserService() public view virtual returns (IRentalityAccessControl) {
    return IRentalityAccessControl(address(0));
  }
}
