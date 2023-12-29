// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";


///  @title UUPSOwnable
/// @dev An upgradeable contract with access control based on both Ownable and UUPS (Universal Upgradeable Proxy Standard).
abstract contract UUPSOwnable is OwnableUpgradeable, UUPSUpgradeable {


    //  @notice Only admins are allowed to authorize upgrades.
    //  @dev Ensures that the owner is the caller during the upgrade process.
    //  @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal view override {
        _checkOwner();
    }
}
