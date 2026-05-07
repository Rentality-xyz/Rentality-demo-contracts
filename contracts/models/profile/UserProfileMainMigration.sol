// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGatewayTokenVerifier} from "@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../base/profile/ProfileBase.sol";
import "../base/profile/ProfileTypes.sol";
import "./UserProfileTypes.sol";
import "../../infrastructure/upgradeable/UUPSOwnable.sol";

contract UserProfileMainMigration is ProfileBase, AccessControlUpgradeable, UUPSOwnable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant HOST_ROLE = keccak256("HOST_ROLE");
    bytes32 public constant GUEST_ROLE = keccak256("GUEST_ROLE");
    bytes32 public constant KYC_COMMISSION_MANAGER_ROLE = keccak256("KYC_MANAGER_ROLE");
    bytes32 public constant ADMIN_VIEW_ROLE = keccak256("ADMIN_VIEW_ROLE");
    bytes32 public constant INVESTMENT_MANAGER_ROLE = keccak256("INVESTMENT_MANAGER_ROLE");
    bytes32 public constant RENTALITY_PLATFORM = keccak256("RENTALITY_PLATFORM_ROLE");
    bytes32 public constant ORACLE_MANAGER = keccak256("ORACLE_MANAGER");

    mapping(address => UserProfileKYCInfo) internal kycInfos;
    mapping(address => UserProfileAdditionalInfo) internal additionalInfos;
    mapping(address => UserProfileCommissionRecord[]) internal userToKycCommission;
    mapping(address => address) internal userCurrencies;
    mapping(address => bool) internal userCurrenciesInitialized;
    address[] internal platformUsers;
    mapping(address => bool) internal userIsInPlatformList;

    address public civicVerifier;
    uint256 public civicGatekeeperNetwork;
    bytes32 public termsMessageHash;
    uint256 public kycCommission;

    struct MigrationProfileImport {
        address user;
        ProfileAccount account;
        ProfileContactInfo contact;
        ProfileConsent consent;
        UserProfileKYCInfo kyc;
        UserProfileAdditionalInfo additional;
        address currency;
        bool currencyInitialized;
        bool includeInPlatformList;
    }

    error InvalidRole(uint8 role);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function migrationImportProfile(MigrationProfileImport calldata item) external onlyOwner {
        _validateProfileUser(item.user);

        ProfileAccount memory account = item.account;
        if (account.wallet == address(0)) {
            account.wallet = item.user;
        }

        profileAccounts[item.user] = account;
        profileContacts[item.user] = item.contact;
        profileConsents[item.user] = item.consent;
        kycInfos[item.user] = item.kyc;
        additionalInfos[item.user] = item.additional;
        userCurrencies[item.user] = item.currency;
        userCurrenciesInitialized[item.user] = item.currencyInitialized;

        if (item.includeInPlatformList && !userIsInPlatformList[item.user]) {
            userIsInPlatformList[item.user] = true;
            platformUsers.push(item.user);
        }
    }

    function migrationGrantRole(address user, UserProfileRole role) external onlyOwner {
        _grantRole(_resolveRole(role), user);
    }

    function migrationClearKycCommissions(address user) external onlyOwner {
        delete userToKycCommission[user];
    }

    function migrationAddKycCommission(address user, UserProfileCommissionRecord calldata record) external onlyOwner {
        userToKycCommission[user].push(record);
    }

    function hasPassedKYC(address user) public view returns (bool) {
        IGatewayTokenVerifier verifier = IGatewayTokenVerifier(civicVerifier);
        return verifier.verifyToken(user, civicGatekeeperNetwork);
    }

    function _resolveRole(UserProfileRole newRole) internal pure returns (bytes32 role) {
        if (newRole == UserProfileRole.Guest) return GUEST_ROLE;
        if (newRole == UserProfileRole.Host) return HOST_ROLE;
        if (newRole == UserProfileRole.Manager) return MANAGER_ROLE;
        if (newRole == UserProfileRole.Admin) return DEFAULT_ADMIN_ROLE;
        if (newRole == UserProfileRole.KYCManager) return KYC_COMMISSION_MANAGER_ROLE;
        if (newRole == UserProfileRole.AdminView) return ADMIN_VIEW_ROLE;
        if (newRole == UserProfileRole.InvestmentManager) return INVESTMENT_MANAGER_ROLE;
        if (newRole == UserProfileRole.OracleManager) return ORACLE_MANAGER;
        revert InvalidRole(uint8(newRole));
    }
}
