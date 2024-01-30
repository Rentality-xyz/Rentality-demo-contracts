// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {UUPSUpgradeable} from '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import '../IRentalityAccessControl.sol';

/// @title UUPSAccess
/// @dev An upgradeable contract with access control based on UUPS (Universal Upgradeable Proxy Standard).
abstract contract UUPSAccess is UUPSUpgradeable {
  IRentalityAccessControl internal userService;

  // @notice Only admins are allowed to authorize upgrades.
  // @dev Ensures that the caller is an admin in the RentalityAccessControl system.
  // @param newImplementation The address of the new implementation contract.
  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(userService.isAdmin(msg.sender), 'Only for Admin.');
  }
}
