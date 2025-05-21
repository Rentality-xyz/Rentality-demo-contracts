// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UserServiceStorage} from "../../libraries/UserServiceStorage.sol";
import {RefferalServiceStorage} from "../../libraries/RefferalServiceStorage.sol";
import "../../../Schemas.sol";
import {IGatewayTokenVerifier} from '@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol';
import "@openzeppelin/contracts/access/IAccessControl.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
 

contract RentalityUserServiceFacet is IAccessControl {

    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    error AccessControlBadConfirmation();

    using UserServiceStorage for UserServiceStorage.UserFaucetStorage;



     modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }


    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        return s._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
       UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        return s._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != msg.sender) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
       UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        s._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
       UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        if (!hasRole(role, account)) {
            s._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, msg.sender);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
       UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
        if (hasRole(role, account)) {
            s._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            return true;
        } else {
            return false;
        }
    }

    function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    bytes4 hash
  ) public {

    address sender = msg.sender;
    RefferalServiceStorage.generateReferralHash(sender);
    bool isUserGuest = _isGuest(sender);
    RefferalServiceStorage.saveRefferalHash(hash, isUserGuest, sender);
    RefferalServiceStorage.passReferralProgram(Schemas.RefferalProgram.SetKYC, bytes(''), sender);
    
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();

     if (isUserGuest) {
      _grantRole(UserServiceStorage.GUEST_ROLE, sender);
    }
    bool isTCPassed = isValidSignatureNow(sender, s.TCMessageHash, TCSignature);

    require(isTCPassed, 'Wrong signature.');
    Schemas.KYCInfo storage kycInfo = s.kycInfos[sender];
    if (kycInfo.createDate == 0 || !_alreadyInPlatformUsersList(s, sender)) s.platformUsers.push(sender);

    string memory oldEmail = s.additionalKycInfo[sender].email;
    if (bytes(oldEmail).length == 0 || !_hasPassedKYC(s, sender)) s.additionalKycInfo[sender].email = email;

    kycInfo.name = nickName;
    if (!_comparePhones(mobilePhoneNumber, kycInfo.mobilePhoneNumber)) s.userToPhoneVerified[sender] = false;

    kycInfo.mobilePhoneNumber = mobilePhoneNumber;
    kycInfo.profilePhoto = profilePhoto;

    if (kycInfo.createDate == 0) kycInfo.createDate = block.timestamp;

    kycInfo.isTCPassed = isTCPassed;
    kycInfo.TCSignature = TCSignature;
  }

    function setMyCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(hasRole(UserServiceStorage.MANAGER_ROLE, msg.sender), 'only Rentality platform');
    Schemas.KYCInfo storage kycInfo = s.kycInfos[user];

    kycInfo.surname = civicKycInfo.fullName;
    kycInfo.licenseNumber = civicKycInfo.licenseNumber;
    kycInfo.expirationDate = civicKycInfo.expirationDate;
    s.additionalKycInfo[user].email = civicKycInfo.email;
    s.additionalKycInfo[user].issueCountry = civicKycInfo.issueCountry;
  }

   function setPhoneNumber(address user, string memory phone, bool isVerified) public {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(hasRole(UserServiceStorage.KYC_COMMISSION_MANAGER_ROLE, msg.sender), 'Only KYC manager');
    s.userToPhoneVerified[user] = isVerified;
    s.kycInfos[user].mobilePhoneNumber = phone;
  }


  
  /// @notice Retrieves KYC information for a specified user.
  /// @param user The address of the user for whom to retrieve KYC information.
  /// @return kycInfo KYCInfo structure containing user's KYC information.
  /// Requirements:
  /// - Caller must be a manager.
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory kycInfo) {
   UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return s.kycInfos[user];
  }
  /// @notice Retrieves KYC information for the caller.
  /// @return kycInfo KYCInfo structure containing caller's KYC information.
  function getMyKYCInfo() external view returns (Schemas.KYCInfo memory kycInfo) {
   UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return s.kycInfos[msg.sender];
  }

  function getMyFullKYCInfo() public view returns (Schemas.FullKYCInfoDTO memory) {
       UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return Schemas.FullKYCInfoDTO(s.kycInfos[msg.sender], s.additionalKycInfo[msg.sender], s.userToPhoneVerified[msg.sender]);
  }
  function getPlatformUsersKYCInfos() public view returns (Schemas.AdminKYCInfoDTO[] memory result) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(hasRole(UserServiceStorage.ADMIN_VIEW_ROLE, msg.sender), 'Only Admin');
    address[] memory users = s.platformUsers;
    result = new Schemas.AdminKYCInfoDTO[](s.platformUsers.length);
    for (uint i = 0; i < result.length; i++) {
      result[i] = Schemas.AdminKYCInfoDTO(s.kycInfos[users[i]], s.additionalKycInfo[users[i]], users[i]);
    }
  }

    function grantAdminRole(address user) public onlyRole(UserServiceStorage.DEFAULT_ADMIN_ROLE) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    grantRole(UserServiceStorage.DEFAULT_ADMIN_ROLE, user);
    grantRole(UserServiceStorage.MANAGER_ROLE, user);
  }
  /// @notice Revokes admin role from a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to revoke admin role.
  function revokeAdminRole(address user) public onlyRole(UserServiceStorage.DEFAULT_ADMIN_ROLE) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    revokeRole(UserServiceStorage.DEFAULT_ADMIN_ROLE, user);
    revokeRole(UserServiceStorage.MANAGER_ROLE, user);
  }
  /// @notice Grants manager role to a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to grant manager role.
  function grantManagerRole(address user) public onlyRole(UserServiceStorage.DEFAULT_ADMIN_ROLE) {
    grantRole(UserServiceStorage.MANAGER_ROLE, user);
  }

    function grantPlatformRole(address user) public onlyRole(UserServiceStorage.DEFAULT_ADMIN_ROLE) {
    grantRole(UserServiceStorage.RENTALITY_PLATFORM, user);
  }
  /// @notice Revokes manager role from a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to revoke manager role.
  function revokeManagerRole(address user) public onlyRole(UserServiceStorage.DEFAULT_ADMIN_ROLE) {
    revokeRole(UserServiceStorage.MANAGER_ROLE, user);
  }


  /// @notice Checks if a user has admin role.
  /// @param user The address of the user to check for admin role.
  /// @return isAdmin A boolean indicating whether the user has admin role.
  function isAdmin(address user) public view returns (bool) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return hasRole(UserServiceStorage.DEFAULT_ADMIN_ROLE, user);
  }
  /// @notice Checks if a user has manager role.
  /// @param user The address of the user to check for manager role.
  /// @return isManager A boolean indicating whether the user has manager role.
  function isManager(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.MANAGER_ROLE, user);
  }

   function isRentalityPlatform(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.RENTALITY_PLATFORM, user);
  }
  /// @notice Checks if a user has host role.
  /// @param user The address of the user to check for host role.
  /// @return isHost A boolean indicating whether the user has host role.
  function isHost(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.HOST_ROLE, user);
  }
  /// @notice Checks if a user has guest role.
  /// @param user The address of the user to check for guest role.
  /// @return isGuest A boolean indicating whether the user has guest role.
  function isGuest(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.GUEST_ROLE, user);
  }
  /// @notice Checks if a user has host or guest role.
  /// @param user The address of the user to check for host or guest role.
  /// @return isHostOrGuest A boolean indicating whether the user has host or guest role.
  function isHostOrGuest(address user) public view returns (bool) {
    return isHost(user) || isGuest(user);
  }

    function isSignatureManager(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.MANAGER_ROLE, user);
  }
  function isInvestorManager(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.INVESTMENT_MANAGER_ROLE, user);
  }
  function isOracleManager(address user) public view returns (bool) {
    return hasRole(UserServiceStorage.ORACLE_MANAGER, user);
  }

  /// @dev Sets the Civic verifier and gatekeeper network for identity verification.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The identifier of the Civic gatekeeper network.
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) public {
    require(isAdmin(msg.sender), 'Only admin.');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();

    s.civicVerifier = _civicVerifier;
    s.civicGatekeeperNetwork = _civicGatekeeperNetwork;
  }

  /// @notice Sets a new message for the Terms and Conditions (TC) and updates the corresponding hashed message.
  /// @dev This function can only be called by an admin.
  /// @param message The new message for the TC.
  function setNewTCMessage(string memory message) public {
    require(isAdmin(msg.sender), 'Only admin.');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    s.TCMessageHash = ECDSA.toEthSignedMessageHash(bytes(message));
  }

  function setKycCommission(uint newCommission) public {
    require(isAdmin(msg.sender), 'Only admin.');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    s.kycCommission = newCommission;
  }

  function getKycCommission() public view returns (uint) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    return s.kycCommission;
  }

  function useKycCommission(address user) public {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(hasRole(UserServiceStorage.KYC_COMMISSION_MANAGER_ROLE, msg.sender) || msg.sender == user, 'only Commission manager');
    Schemas.KycCommissionData[] memory commissions = s.userToKYCCommission[user];
    if (commissions.length == 0) {
      revert('not paid');
    }
    require(commissions[commissions.length - 1].commissionPaid, 'not paid');
    commissions[commissions.length - 1].commissionPaid = false;
    s.userToKYCCommission[user] = commissions;
  }

  function isCommissionPaidForUser(address user) public view returns (bool) {
    require(isRentalityPlatform(user) || msg.sender == user, 'Not allowed');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    Schemas.KycCommissionData[] memory commissions = s.userToKYCCommission[user];
    if (commissions.length == 0) return false;
    return commissions[commissions.length - 1].commissionPaid;
  }

  function payCommission(address user) public {
    require(isRentalityPlatform(msg.sender), 'only Rentality platform.');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    s.userToKYCCommission[user].push(Schemas.KycCommissionData(block.timestamp, true));
  }

  function manageRole(Schemas.Role newRole, address user, bool grant) public {
    require(isAdmin(msg.sender), 'only admin');
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    bytes32 role;
    if (newRole == Schemas.Role.Guest) role = UserServiceStorage.GUEST_ROLE;
    else if (newRole == Schemas.Role.Host) role = UserServiceStorage.HOST_ROLE;
    else if (newRole == Schemas.Role.Manager) role = UserServiceStorage.MANAGER_ROLE;
    else if (newRole == Schemas.Role.Admin) role = UserServiceStorage.DEFAULT_ADMIN_ROLE;
    else if (newRole == Schemas.Role.KYCManager) role = UserServiceStorage.KYC_COMMISSION_MANAGER_ROLE;
    else if (newRole == Schemas.Role.AdminView) role = UserServiceStorage.ADMIN_VIEW_ROLE;
    else if (newRole == Schemas.Role.InvestmentManager) role = UserServiceStorage.INVESTMENT_MANAGER_ROLE;
    else if(newRole == Schemas.Role.OracleManager) role = UserServiceStorage.ORACLE_MANAGER;
    else revert('Invalid role');
    if (grant) _grantRole(role, user);
    else {
      _revokeRole(role, user);
    }
  }

  function getPlatformUsers() public view returns (address[] memory) {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(hasRole(UserServiceStorage.ADMIN_VIEW_ROLE, msg.sender), 'Only Admin');
    return s.platformUsers;
  }



  function _alreadyInPlatformUsersList(UserServiceStorage.UserFaucetStorage storage s, address user) private view returns (bool) {
    address[] memory users = s.platformUsers;
    for (uint i = 0; i < users.length; i++) {
      if (users[i] == user) return true;
    }
    return false;
  }

  function _comparePhones(string memory p1, string memory p2) private pure returns (bool) {
    return keccak256(abi.encodePacked(p1)) == keccak256(abi.encodePacked(p2));
  }
    function _hasPassedKYC(UserServiceStorage.UserFaucetStorage storage s, address user) private view returns (bool) {
    IGatewayTokenVerifier verifier = IGatewayTokenVerifier(s.civicVerifier);
    return verifier.verifyToken(user, s.civicGatekeeperNetwork);
  }

    function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    UserServiceStorage.UserFaucetStorage storage s = UserServiceStorage.accessStorage();
    require(UserServiceStorage.hasRole(UserServiceStorage.KYC_COMMISSION_MANAGER_ROLE, msg.sender), 'Only KYC manager');
    Schemas.KYCInfo storage kycInfo = s.kycInfos[user];

    kycInfo.surname = civicKycInfo.fullName;
    kycInfo.licenseNumber = civicKycInfo.licenseNumber;
    kycInfo.expirationDate = civicKycInfo.expirationDate;
    s.additionalKycInfo[user].email = civicKycInfo.email;
    s.additionalKycInfo[user].issueCountry = civicKycInfo.issueCountry;
  }


  

   function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
    if (signer.code.length == 0) {
      (address recovered, ECDSA.RecoverError err) = ECDSA.tryRecover(hash, signature);
      return err == ECDSA.RecoverError.NoError && recovered == signer;
    } else {
      return isValidERC1271SignatureNow(signer, hash, signature);
    }
  }

   function isValidERC1271SignatureNow(
    address signer,
    bytes32 hash,
    bytes memory signature
  ) internal view returns (bool) {
    (bool success, bytes memory result) = signer.staticcall(
      abi.encodeCall(IERC1271.isValidSignature, (hash, signature))
    );
    return (success &&
      result.length >= 32 &&
      abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
  }


  function _isGuest(address user) private view returns (bool) {
    return hasRole(UserServiceStorage.GUEST_ROLE, user);
  }

}