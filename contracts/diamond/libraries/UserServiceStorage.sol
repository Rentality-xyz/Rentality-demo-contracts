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

    bytes32 MANAGER_ROLE;
    bytes32 HOST_ROLE;
    bytes32 GUEST_ROLE;
    bytes32 KYC_COMMISSION_MANAGER_ROLE;
    bytes32 ADMIN_VIEW_ROLE;
    bytes32 INVESTMENT_MANAGER_ROLE;
    bytes32 RENTALITY_PLATFORM;
    bytes32 ORACLE_MANAGER;

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

   function isAdmin(address user) internal view returns (bool) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return hasRole(s.DEFAULT_ADMIN_ROLE, user);
  }
  function isHost(address user) internal view returns (bool) {
    return hasRole(accessStorage().HOST_ROLE, user);
  }

   function hasRole(bytes32 role, address account) internal view returns (bool) {
        UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        return s._roles[role].hasRole[account];
    }
     function isSignatureManager(address user) internal view returns (bool) {
        return hasRole(accessStorage().MANAGER_ROLE, user);
   }
   function grantHostRole(address user) internal returns(bool) {
    UserFaucetStorage storage s = accessStorage();
      if (!hasRole(s.HOST_ROLE, user)) {
            s._roles[s.HOST_ROLE].hasRole[user] = true;
            return true;
        } else {
            return false;
        }
  }

    function getKYCInfo(address user) internal view returns (Schemas.KYCInfo memory kycInfo) {
        UserFaucetStorage storage s = accessStorage();
        return s.kycInfos[user];
  }

  function isCommissionPaidForUser(address user) internal view returns (bool) {
    UserFaucetStorage storage s = accessStorage();
    Schemas.KycCommissionData[] memory commissions = s.userToKYCCommission[user];
    if (commissions.length == 0) return false;
    return commissions[commissions.length - 1].commissionPaid;
  }

   function payCommission(address user) internal {
    UserFaucetStorage storage s = accessStorage();
    s.userToKYCCommission[user].push(Schemas.KycCommissionData(block.timestamp, true));
  }

  

 function accessStorage() internal pure returns (UserFaucetStorage storage ds) {
        bytes32 position = LibDiamond.ACCESS_STORAGE_POSITION;
        assembly { ds.slot := position }
    }


}