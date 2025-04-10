// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";

library UserServiceStorage {

     bytes32 constant ACCESS_STORAGE_POSITION = 
        keccak256("diamond.access.storage");
     struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    struct UserFaucetStorage {

    mapping(bytes32 role => RoleData) _roles;

    bytes32 DEFAULT_ADMIN_ROLE;

    mapping(address => Schemas.KYCInfo) kycInfos;
    address civicVerifier;
    uint civicGatekeeperNetwork;
    bytes32 TCMessageHash;
    uint kycCommission;
    mapping(address => Schemas.KycCommissionData[]) userToKYCCommission;
    mapping(address => Schemas.AdditionalKYCInfo) additionalKycInfo;
    address[] platformUsers;
    mapping(address => bool) userToPhoneVerified;
}

 function hasPassedKYCAndTC(address user) internal view returns (bool) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return s.kycInfos[user].isTCPassed;
  }

 function accessStorage() internal pure returns (UserFaucetStorage storage ds) {
        bytes32 position = LibDiamond.ACCESS_STORAGE_POSITION;
        assembly { ds.slot := position }
    }


}