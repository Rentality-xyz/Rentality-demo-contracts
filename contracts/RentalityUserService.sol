// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './Schemas.sol';
/// @title RentalityUserService Contract
/// @notice
/// This contract manages user roles and KYC (Know Your Customer) information.
/// Users can have roles such as Manager, Host, and Guest. KYC information includes
/// personal details, mobile phone number, profile photo, license number, and expiration date.
/// The contract utilizes the AccessControl library for role-based access control.
///
/// The contract includes functions to set and retrieve KYC information, check for valid KYC,
/// grant and revoke roles, and check user roles
contract RentalityUserService is AccessControlUpgradeable, UUPSUpgradeable {
  // Role identifiers for access control
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
  bytes32 public constant HOST_ROLE = keccak256('HOST_ROLE');
  bytes32 public constant GUEST_ROLE = keccak256('GUEST_ROLE');

  // Mapping to store KYC information for each user address
  mapping(address => Schemas.KYCInfo) private kycInfos;

  /// @notice Sets KYC information for the caller (host or guest).
  /// @param name The user's name.
  /// @param surname The user's surname.
  /// @param mobilePhoneNumber The user's mobile phone number.
  /// @param profilePhoto The URL or identifier of the user's profile photo.
  /// @param licenseNumber The user's license number.
  /// @param expirationDate The expiration date of the user's license.
  /// Requirements:
  /// - Caller must be a host or guest.
  function setKYCInfo(
    string memory name,
    string memory surname,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory licenseNumber,
    uint64 expirationDate
  ) public {
    require(isHostOrGuest(tx.origin), 'Only for hosts or guests');

    kycInfos[tx.origin] = Schemas.KYCInfo(
      name,
      surname,
      mobilePhoneNumber,
      profilePhoto,
      licenseNumber,
      expirationDate,
      block.timestamp
    );
  }
  /// @notice Retrieves KYC information for a specified user.
  /// @param user The address of the user for whom to retrieve KYC information.
  /// @return kycInfo KYCInfo structure containing user's KYC information.
  /// Requirements:
  /// - Caller must be a manager.
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory kycInfo) {
    require(isManager(msg.sender), 'Only the manager can get other users KYC info');
    return kycInfos[user];
  }
  /// @notice Retrieves KYC information for the caller.
  /// @return kycInfo KYCInfo structure containing caller's KYC information.
  function getMyKYCInfo() external view returns (Schemas.KYCInfo memory kycInfo) {
    return kycInfos[tx.origin];
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

  function initialize() public virtual initializer {
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantRole(MANAGER_ROLE, msg.sender);
    grantRole(HOST_ROLE, msg.sender);
    grantRole(GUEST_ROLE, msg.sender);
    _setRoleAdmin(HOST_ROLE, MANAGER_ROLE);
    _setRoleAdmin(GUEST_ROLE, MANAGER_ROLE);
  }

  function _authorizeUpgrade(address newImplementation) internal view override {
    require(isAdmin(msg.sender), 'Only for Admin.');
  }
}
