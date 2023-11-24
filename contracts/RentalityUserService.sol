// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

//deployed 26.05.2023 11:15 to sepolia at 0xF5d6E451600439BBd282B0001b56019E5F4662bf
contract RentalityUserService is AccessControl {
    struct KYCInfo {
        string name;
        string surname;
        string mobilePhoneNumber;
        string profilePhoto;
        string licenseNumber;
        uint64 expirationDate;
        uint createDate;
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

    function setKYCInfo(
        string memory name,
        string memory surname,
        string memory mobilePhoneNumber,
        string memory profilePhoto,
        string memory licenseNumber,
        uint64 expirationDate
    ) public {
        require(isHostOrGuest(tx.origin), "Only for hosts or guests");

        kycInfos[tx.origin] = KYCInfo(
            name,
            surname,
            mobilePhoneNumber,
            profilePhoto,
            licenseNumber,
            expirationDate,
            block.timestamp
        );
    }

    function getKYCInfo(address user) external view returns (KYCInfo memory) {
        require(isManager(msg.sender), 'Only the manager can get other users KYC info');
        return kycInfos[user];
    }

    function getMyKYCInfo() external view returns (KYCInfo memory) {
        return kycInfos[tx.origin];
    }

    function hasValidKYC(address user) public view returns (bool) {
        KYCInfo memory kycInfo = kycInfos[user];
        return
            kycInfo.createDate > 0 && kycInfo.expirationDate > block.timestamp;
    }

    function grantAdminRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, user);
        grantRole(MANAGER_ROLE, user);
    }

    function revokeAdminRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, user);
        revokeRole(MANAGER_ROLE, user);
    }

    function grantManagerRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, user);
    }

    function revokeManagerRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, user);
    }

    function grantHostRole(address user) public onlyRole(MANAGER_ROLE) {
        _grantRole(HOST_ROLE, user);
    }

    function revokeHostRole(address user) public onlyRole(MANAGER_ROLE) {
        revokeRole(HOST_ROLE, user);
    }

    function grantGuestRole(address user) public onlyRole(MANAGER_ROLE) {
        _grantRole(GUEST_ROLE, user);
    }

    function revokeGuestRole(address user) public onlyRole(MANAGER_ROLE) {
        revokeRole(GUEST_ROLE, user);
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
}
