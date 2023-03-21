// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RentalityUserService is AccessControl {
    struct KYCInfo {
        string licenseNumber;
        uint256 expirationDate;
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant HOST_ROLE = keccak256("HOST_ROLE");
    bytes32 public constant GUEST_ROLE = keccak256("GUEST_ROLE");

    mapping(address => KYCInfo) private kycInfos;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, msg.sender);
        grantRole(HOST_ROLE, msg.sender);
        grantRole(GUEST_ROLE, msg.sender);
        _setRoleAdmin(HOST_ROLE, MANAGER_ROLE);
        _setRoleAdmin(GUEST_ROLE, MANAGER_ROLE);
    }

    function grantAdminRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, user);
    }

    function grantManagerRole(
        address user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, user);
    }

    function grantHostRole(address user) public onlyRole(MANAGER_ROLE) {
        grantRole(HOST_ROLE, user);
    }

    function grantGuestRole(address user) public onlyRole(MANAGER_ROLE) {
        grantRole(GUEST_ROLE, user);
    }

    function isAdmin(address user) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }

    function isManager(address user) public view returns (bool) {
        return hasRole(MANAGER_ROLE, user);
    }

    function isHost(address user) public view returns (bool) {
        return hasRole(HOST_ROLE, user);
    }

    function isGuest(address user) public view returns (bool) {
        return hasRole(GUEST_ROLE, user);
    }

    function isHostOrGuest(address user) public view returns (bool) {
        return isHost(user) || isGuest(user);
    }

    function setKYCInfo(address user, KYCInfo memory kycInfo) public {
        kycInfos[user] = kycInfo;
    }

    function getKYCInfo(address user) external view returns (KYCInfo memory) {
        return kycInfos[user];
    }

    function hasValidKYC(address user) public view returns (bool) {
        KYCInfo memory kycInfo = kycInfos[user];
        return kycInfo.expirationDate > block.timestamp;
    }
}
