// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UserServiceStorage} from  "../../libraries/UserServiceStorage.sol";
import {GeoServiceStorage} from "../../libraries/GeoServiceStorage.sol";

contract RentalityGeoServiceFacet {

    function setVerifier(address verifier) external {
       require(UserServiceStorage.isAdmin(msg.sender), "Only for Admin.");
       GeoServiceStorage.setVerifier(verifier);
    }
}