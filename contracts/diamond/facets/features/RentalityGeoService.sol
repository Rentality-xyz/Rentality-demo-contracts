// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/UserServiceStorage.sol";
import "../../libraries/GeoServiceStorage.sol";

contract RentalityGeoService {
    function setVerifier(address verifier) external {
       require(UserServiceStorage.isAdmin(msg.sender), "Only for Admin.");
       GeoServiceStorage.setVerifier(verifier);
    }
}