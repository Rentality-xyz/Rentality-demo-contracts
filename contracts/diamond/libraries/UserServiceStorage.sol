// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../Schemas.sol";
import { LibDiamond } from "./LibDiamond.sol";


library UserServiceStorage {

     bytes32 constant ACCESS_STORAGE_POSITION = 
        keccak256("diamond.access.storage");

      bytes32 internal constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
      bytes32 internal constant HOST_ROLE = keccak256('HOST_ROLE');
      bytes32 internal constant GUEST_ROLE = keccak256('GUEST_ROLE');
      bytes32 internal constant KYC_COMMISSION_MANAGER_ROLE = keccak256('KYC_MANAGER_ROLE');
      bytes32 internal constant ADMIN_VIEW_ROLE = keccak256('ADMIN_VIEW_ROLE');
      bytes32 internal constant INVESTMENT_MANAGER_ROLE = keccak256('INVESTMENT_MANAGER_ROLE');
      
      bytes32 internal constant RENTALITY_PLATFORM = keccak256('RENTALITY_PLATFORM_ROLE');

      bytes32 internal constant ORACLE_MANAGER = keccak256('ORACLE_MANAGER');
        bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
     struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    struct UserFaucetStorage {

    mapping(bytes32 role => RoleData) _roles;

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
    return hasRole(UserServiceStorage.DEFAULT_ADMIN_ROLE, user);
  }
  function isHost(address user) internal view returns (bool) {
    return hasRole(UserServiceStorage.HOST_ROLE, user);
  }

   function hasRole(bytes32 role, address account) internal view returns (bool) {
        UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        return s._roles[role].hasRole[account];
    }
     function isSignatureManager(address user) internal view returns (bool) {
        return hasRole(UserServiceStorage.MANAGER_ROLE, user);
   }
   function grantHostRole(address user) internal returns(bool) {
    UserFaucetStorage storage s = accessStorage();
      if (!hasRole(UserServiceStorage.HOST_ROLE, user)) {
            s._roles[UserServiceStorage.HOST_ROLE].hasRole[user] = true;
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

   function getMyFullKYCInfo(address user) internal view returns (Schemas.FullKYCInfoDTO memory) {
    UserFaucetStorage storage s = accessStorage();
    return Schemas.FullKYCInfoDTO(s.kycInfos[user], s.additionalKycInfo[user], s.userToPhoneVerified[user]);
  }

  function getKycCommission() internal view returns (uint) {
    UserFaucetStorage storage s = accessStorage();
    return s.kycCommission;
  }
  
      function _grantRole(bytes32 role, address account) internal returns (bool) {
       UserFaucetStorage storage s = accessStorage();
        if (!hasRole(role, account)) {
            s._roles[role].hasRole[account] = true;
            return true;
        } else {
            return false;
        }
    }


 function accessStorage() internal pure returns (UserFaucetStorage storage ds) {
        bytes32 position = LibDiamond.ACCESS_STORAGE_POSITION;
        assembly { ds.slot := position }
    }


}