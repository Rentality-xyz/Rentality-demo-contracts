// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IGatewayTokenVerifier} from '@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './Schemas.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {IRentalityAccessControl} from './abstract/IRentalityAccessControl.sol';

/// @title RentalityUserService Contract
/// @notice
/// This contract manages user roles and KYC (Know Your Customer) information.
/// Users can have roles such as Manager, Host, and Guest. KYC information includes
/// personal details, mobile phone number, profile photo, license number, and expiration date.
/// The contract utilizes the AccessControl library for role-based access control.
///
/// The contract includes functions to set and retrieve KYC information, check for valid KYC,
/// grant and revoke roles, and check user roles
contract RentalityUserService is AccessControlUpgradeable, UUPSUpgradeable, IRentalityAccessControl {
  // Role identifiers for access control
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
  bytes32 public constant HOST_ROLE = keccak256('HOST_ROLE');
  bytes32 public constant GUEST_ROLE = keccak256('GUEST_ROLE');
  bytes32 public constant KYC_COMMISSION_MANAGER_ROLE = keccak256('KYC_MANAGER_ROLE');
  bytes32 public constant ADMIN_VIEW_ROLE = keccak256('ADMIN_VIEW_ROLE');

  // Mapping to store KYC information for each user address
  mapping(address => Schemas.KYCInfo) private kycInfos;
  address private civicVerifier;
  uint private civicGatekeeperNetwork;
  bytes32 private TCMessageHash;
  uint private kycCommission;
  mapping(address => Schemas.KycCommissionData[]) private userToKYCCommission;
  mapping(address => Schemas.AdditionalKYCInfo) private additionalKycInfo;
  address[] private platformUsers;

  /// @notice Sets KYC information for the caller (host or guest).
  /// Requirements:
  /// - Caller must be a host or guest.
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    address user
  ) public {
    require(isManager(msg.sender),"only Manager");
    if (!isGuest(user)) {
      _grantRole(GUEST_ROLE, user);
    }
    bool isTCPassed = ECDSA.recover(TCMessageHash, TCSignature) == user;

    require(isTCPassed, 'Wrong signature.');
    Schemas.KYCInfo storage kycInfo = kycInfos[user];
    if(kycInfo.createDate == 0 || !_alreadyInPlatformUsersList(user))
      platformUsers.push(user);

    string memory oldEmail = additionalKycInfo[user].email;
    if(bytes(oldEmail).length == 0 || !hasPassedKYC(user))
    additionalKycInfo[user].email = email;

    kycInfo.name = nickName;
    kycInfo.mobilePhoneNumber = mobilePhoneNumber;
    kycInfo.profilePhoto = profilePhoto;

    if (kycInfo.createDate == 0) kycInfo.createDate = block.timestamp;

    kycInfo.isTCPassed = isTCPassed;
    kycInfo.TCSignature = TCSignature;
  }

  function setMyCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    require(hasRole(MANAGER_ROLE, msg.sender), 'Only manager');
    Schemas.KYCInfo storage kycInfo = kycInfos[user];

    kycInfo.surname = civicKycInfo.fullName;
    kycInfo.licenseNumber = civicKycInfo.licenseNumber;
    kycInfo.expirationDate = civicKycInfo.expirationDate;
    additionalKycInfo[user].email = civicKycInfo.email;
    additionalKycInfo[user].issueCountry = civicKycInfo.issueCountry;
  }

  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) public {
    require(hasRole(KYC_COMMISSION_MANAGER_ROLE, tx.origin), 'Only KYC manager');
    Schemas.KYCInfo storage kycInfo = kycInfos[user];

    kycInfo.surname = civicKycInfo.fullName;
    kycInfo.licenseNumber = civicKycInfo.licenseNumber;
    kycInfo.expirationDate = civicKycInfo.expirationDate;
    additionalKycInfo[user].email = civicKycInfo.email;
    additionalKycInfo[user].issueCountry = civicKycInfo.issueCountry;
  }
  /// @notice Retrieves KYC information for a specified user.
  /// @param user The address of the user for whom to retrieve KYC information.
  /// @return kycInfo KYCInfo structure containing user's KYC information.
  /// Requirements:
  /// - Caller must be a manager.
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory kycInfo) {
    // require(isManager(msg.sender), 'Only the manager can get other users KYC info');
    return kycInfos[user];
  }
  /// @notice Retrieves KYC information for the caller.
  /// @return kycInfo KYCInfo structure containing caller's KYC information.
  function getMyKYCInfo(address user) external view returns (Schemas.KYCInfo memory kycInfo) {
    require(isManager(msg.sender),"only Manager");
    return kycInfos[user];
  }

  function getMyFullKYCInfo(address user) public view returns (Schemas.FullKYCInfoDTO memory) {
    return Schemas.FullKYCInfoDTO(kycInfos[user], additionalKycInfo[user]);
  }
  function getPlatformUsersKYCInfos() public view returns (Schemas.AdminKYCInfoDTO[] memory result) {
    require(hasRole(ADMIN_VIEW_ROLE, tx.origin), 'Only Admin');
    address[] memory users = platformUsers;
    result = new Schemas.AdminKYCInfoDTO[](platformUsers.length);
    for (uint i = 0; i < result.length; i++) {
      result[i] = Schemas.AdminKYCInfoDTO(kycInfos[users[i]], additionalKycInfo[users[i]], users[i]);
    }
  }
  /// @notice Checks if the KYC information for a specified user is valid.
  /// @param user The address of the user to check for valid KYC.
  /// @return isValid A boolean indicating whether the user has valid KYC information.
  function hasValidKYC(address user) public view returns (bool isValid) {
    Schemas.KYCInfo memory kycInfo = kycInfos[user];
    return kycInfo.createDate > 0 && kycInfo.expirationDate > block.timestamp;
  }
  /// @notice Grants admin role to a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to grant admin role.
  function grantAdminRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(DEFAULT_ADMIN_ROLE, user);
    grantRole(MANAGER_ROLE, user);
  }
  /// @notice Revokes admin role from a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to revoke admin role.
  function revokeAdminRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(DEFAULT_ADMIN_ROLE, user);
    revokeRole(MANAGER_ROLE, user);
  }
  /// @notice Grants manager role to a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to grant manager role.
  function grantManagerRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MANAGER_ROLE, user);
  }
  /// @notice Revokes manager role from a specified user.
  /// Requirements:
  /// - Caller must have DEFAULT_ADMIN_ROLE.
  /// @param user The address of the user to revoke manager role.
  function revokeManagerRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(MANAGER_ROLE, user);
  }
  /// @notice Grants host role to a specified user.
  /// Requirements:
  /// - Caller must have MANAGER_ROLE.
  /// @param user The address of the user to grant host role.
  function grantHostRole(address user) public onlyRole(MANAGER_ROLE) {
    _grantRole(HOST_ROLE, user);
  }
  /// @notice Revokes host role from a specified user.
  /// Requirements:
  /// - Caller must have MANAGER_ROLE.
  /// @param user The address of the user to revoke host role.
  function revokeHostRole(address user) public onlyRole(MANAGER_ROLE) {
    revokeRole(HOST_ROLE, user);
  }
  /// @notice Grants guest role to a specified user.
  /// Requirements:
  /// - Caller must have MANAGER_ROLE.
  /// @param user The address of the user to grant guest role.
  function grantGuestRole(address user) public onlyRole(MANAGER_ROLE) {
    _grantRole(GUEST_ROLE, user);
  }
  /// @notice Revokes guest role from a specified user.
  /// Requirements:
  /// - Caller must have MANAGER_ROLE.
  /// @param user The address of the user to revoke guest role.
  function revokeGuestRole(address user) public onlyRole(MANAGER_ROLE) {
    revokeRole(GUEST_ROLE, user);
  }

  /// @notice Checks if a user has passed KYC.
  /// @param user The address of the user to check KYC status for.
  /// @return A boolean indicating whether the user has passed KYC.
  function hasPassedKYC(address user) public view returns (bool) {
    IGatewayTokenVerifier verifier = IGatewayTokenVerifier(civicVerifier);
    return verifier.verifyToken(user, civicGatekeeperNetwork);
  }

  /// @notice Checks if a user has passed both KYC (Know Your Customer) and TC (Terms and Conditions).
  /// @param user The address of the user whose KYC and TC status is being checked.
  /// @return A boolean indicating whether the user has passed both KYC and TC.
  function hasPassedKYCAndTC(address user) public view returns (bool) {
    return kycInfos[user].isTCPassed;
  }

  /// @notice Checks if a user has admin role.
  /// @param user The address of the user to check for admin role.
  /// @return isAdmin A boolean indicating whether the user has admin role.
  function isAdmin(address user) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, user);
  }
  /// @notice Checks if a user has manager role.
  /// @param user The address of the user to check for manager role.
  /// @return isManager A boolean indicating whether the user has manager role.
  function isManager(address user) public view returns (bool) {
    return hasRole(MANAGER_ROLE, user);
  }
  /// @notice Checks if a user has host role.
  /// @param user The address of the user to check for host role.
  /// @return isHost A boolean indicating whether the user has host role.
  function isHost(address user) public view returns (bool) {
    return hasRole(HOST_ROLE, user);
  }
  /// @notice Checks if a user has guest role.
  /// @param user The address of the user to check for guest role.
  /// @return isGuest A boolean indicating whether the user has guest role.
  function isGuest(address user) public view returns (bool) {
    return hasRole(GUEST_ROLE, user);
  }
  /// @notice Checks if a user has host or guest role.
  /// @param user The address of the user to check for host or guest role.
  /// @return isHostOrGuest A boolean indicating whether the user has host or guest role.
  function isHostOrGuest(address user) public view returns (bool) {
    return isHost(user) || isGuest(user);
  }

  /// @dev Sets the Civic verifier and gatekeeper network for identity verification.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The identifier of the Civic gatekeeper network.
  function setCivicData(address _civicVerifier, uint _civicGatekeeperNetwork) public {
    require(isAdmin(msg.sender), 'Only admin.');

    civicVerifier = _civicVerifier;
    civicGatekeeperNetwork = _civicGatekeeperNetwork;
  }

  /// @notice Sets a new message for the Terms and Conditions (TC) and updates the corresponding hashed message.
  /// @dev This function can only be called by an admin.
  /// @param message The new message for the TC.
  function setNewTCMessage(string memory message) public {
    require(isAdmin(msg.sender), 'Only admin.');
    TCMessageHash = ECDSA.toEthSignedMessageHash(bytes(message));
  }

  function setKycCommission(uint newCommission) public {
    require(isAdmin(tx.origin), 'Only admin.');
    kycCommission = newCommission;
  }

  function getKycCommission() public view returns (uint) {
    return kycCommission;
  }

  function useKycCommission(address user) public {
    require(hasRole(KYC_COMMISSION_MANAGER_ROLE, tx.origin) || msg.sender == user, 'only Manager');

    Schemas.KycCommissionData[] memory commissions = userToKYCCommission[user];
    if (commissions.length == 0) {
      revert('not paid');
    }
    require(commissions[commissions.length - 1].commissionPaid, 'not paid');
    commissions[commissions.length - 1].commissionPaid = false;
    userToKYCCommission[user] = commissions;
  }

  function isCommissionPaidForUser(address user) public view returns (bool) {
    require(isManager(user) || tx.origin == user, 'Not allowed');
    Schemas.KycCommissionData[] memory commissions = userToKYCCommission[user];
    if (commissions.length == 0) return false;
    return commissions[commissions.length - 1].commissionPaid;
  }

  function payCommission(address user) public {
    require(isManager(msg.sender), 'only manager.');
    userToKYCCommission[user].push(Schemas.KycCommissionData(block.timestamp, true));
  }

  function manageRole(Schemas.Role newRole, address user, bool grant) public {
    require(isAdmin(tx.origin), 'only admin');
    bytes32 role;
    if (newRole == Schemas.Role.Guest) role = GUEST_ROLE;
    else if (newRole == Schemas.Role.Host) role = HOST_ROLE;
    else if (newRole == Schemas.Role.Manager) role = MANAGER_ROLE;
    else if (newRole == Schemas.Role.Admin) role = DEFAULT_ADMIN_ROLE;
    else if (newRole == Schemas.Role.KYCManager) role = KYC_COMMISSION_MANAGER_ROLE;
    else if (newRole == Schemas.Role.AdminView) role = ADMIN_VIEW_ROLE;
    else revert('Invalid role');
    if (grant) _grantRole(role, user);
    else {
      _revokeRole(role, user);
    }
  }

  function getPlatformUsers() public view returns (address[] memory) {
    require(hasRole(ADMIN_VIEW_ROLE, tx.origin), 'Only Admin');
    return platformUsers;
  }

  function _alreadyInPlatformUsersList(address user) private view returns (bool) {
    address[] memory users = platformUsers;
    for (uint i = 0; i < users.length; i++) {
      if (users[i] == user) return true;
    }
    return false;
  }
  function isSignatureManager(address user) public view returns (bool) {
    return hasRole(MANAGER_ROLE, user);
  }

  /// @notice Initializes the contract with the specified Civic verifier address and gatekeeper network ID, and sets the default admin role.
  /// @dev This function is called during contract deployment.
  /// @param _civicVerifier The address of the Civic verifier contract.
  /// @param _civicGatekeeperNetwork The ID of the Civic gatekeeper network.
  function initialize(address _civicVerifier, uint _civicGatekeeperNetwork) public virtual initializer {
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantRole(MANAGER_ROLE, msg.sender);
    grantRole(HOST_ROLE, msg.sender);
    grantRole(GUEST_ROLE, msg.sender);
    _setRoleAdmin(HOST_ROLE, MANAGER_ROLE);
    _setRoleAdmin(GUEST_ROLE, MANAGER_ROLE);

    civicVerifier = _civicVerifier;
    civicGatekeeperNetwork = _civicGatekeeperNetwork;
    TCMessageHash = ECDSA.toEthSignedMessageHash(
      'I have read and I agree with Terms of service, Cancellation policy, Prohibited uses and Privacy policy of Rentality.'
    );
    kycCommission = 200;
  }

  function _authorizeUpgrade(address /*newImplementation*/) internal view override {
    require(isAdmin(msg.sender), 'Only for Admin.');
  }
}
