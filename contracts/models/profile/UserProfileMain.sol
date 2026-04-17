// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGatewayTokenVerifier} from '@identity.com/gateway-protocol-eth/contracts/interfaces/IGatewayTokenVerifier.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../base/profile/ProfileBase.sol';
import './UserProfileTypes.sol';
import '../../infrastructure/upgradeable/UUPSOwnable.sol';

contract UserProfileMain is ProfileBase, AccessControlUpgradeable, UUPSOwnable {
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
    bytes32 public constant HOST_ROLE = keccak256('HOST_ROLE');
    bytes32 public constant GUEST_ROLE = keccak256('GUEST_ROLE');
    bytes32 public constant KYC_COMMISSION_MANAGER_ROLE = keccak256('KYC_MANAGER_ROLE');
    bytes32 public constant ADMIN_VIEW_ROLE = keccak256('ADMIN_VIEW_ROLE');
    bytes32 public constant INVESTMENT_MANAGER_ROLE = keccak256('INVESTMENT_MANAGER_ROLE');
    bytes32 public constant RENTALITY_PLATFORM = keccak256('RENTALITY_PLATFORM_ROLE');
    bytes32 public constant ORACLE_MANAGER = keccak256('ORACLE_MANAGER');

    mapping(address => UserProfileKYCInfo) internal kycInfos;
    mapping(address => UserProfileAdditionalInfo) internal additionalInfos;
    mapping(address => UserProfileCommissionRecord[]) internal userToKycCommission;
    address[] internal platformUsers;
    mapping(address => bool) internal userIsInPlatformList;

    address public civicVerifier;
    uint256 public civicGatekeeperNetwork;
    bytes32 public termsMessageHash;
    uint256 public kycCommission;

    error OnlyPlatform();
    error OnlyAdmin();
    error OnlyKycManager();
    error InvalidRole(uint8 role);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address civicVerifierAddress, uint256 civicGatekeeperNetworkId) public initializer {
        __AccessControl_init();
        __Ownable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(HOST_ROLE, msg.sender);
        _grantRole(GUEST_ROLE, msg.sender);
        _grantRole(RENTALITY_PLATFORM, msg.sender);
        _setRoleAdmin(HOST_ROLE, MANAGER_ROLE);
        _setRoleAdmin(GUEST_ROLE, MANAGER_ROLE);

        civicVerifier = civicVerifierAddress;
        civicGatekeeperNetwork = civicGatekeeperNetworkId;
        termsMessageHash = ECDSA.toEthSignedMessageHash(
            'I have read and I agree with Terms of service, Cancellation policy, Prohibited uses and Privacy policy of Rentality.'
        );
        kycCommission = 200;
    }

    modifier onlyPlatform() {
        if (!isRentalityPlatform(msg.sender)) {
            revert OnlyPlatform();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!(isAdmin(msg.sender) || isAdmin(tx.origin))) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyKycManager() {
        if (!(hasRole(KYC_COMMISSION_MANAGER_ROLE, tx.origin) || hasRole(KYC_COMMISSION_MANAGER_ROLE, msg.sender))) {
            revert OnlyKycManager();
        }
        _;
    }

    function setPushToken(address user, string memory pushToken) external onlyKycManager {
        _setPushToken(user, pushToken);
    }

    function setKYCInfo(SetUserProfileRequest calldata request, address user) external onlyPlatform {
        if (!isGuest(user)) {
            _grantRole(GUEST_ROLE, user);
        }

        _touchPlatformUser(user);

        if (!_sameString(request.email, additionalInfos[user].email)) {
            _setEmailVerified(user, false);
            additionalInfos[user].email = request.email;
        }

        if (!_sameString(request.mobilePhoneNumber, kycInfos[user].mobilePhoneNumber)) {
            _setPhoneVerified(user, false);
        }

        _setProfileIdentity(user, request.nickName, request.profilePhoto);
        _setProfileContact(user, request.mobilePhoneNumber, request.email);
        _setProfileConsent(user, true, request.termsSignature);

        UserProfileKYCInfo storage kycInfo = kycInfos[user];
        kycInfo.name = request.nickName;
        kycInfo.mobilePhoneNumber = request.mobilePhoneNumber;
        kycInfo.profilePhoto = request.profilePhoto;
        kycInfo.isTermsPassed = true;
        kycInfo.termsSignature = request.termsSignature;
        if (kycInfo.createDate == 0) {
            kycInfo.createDate = block.timestamp;
        }
    }

    function setMyCivicKYCInfo(address user, CivicUserProfileInfo calldata civicKycInfo) external {
        require(hasRole(MANAGER_ROLE, msg.sender), 'only Rentality platform');
        _applyCivicKycInfo(user, civicKycInfo, false);
    }

    function setCivicKYCInfo(address user, CivicUserProfileInfo calldata civicKycInfo) external onlyKycManager {
        _applyCivicKycInfo(user, civicKycInfo, true);
    }

    function setPhoneNumber(address user, string calldata phone, bool isVerified) external onlyKycManager {
        _setProfileContact(user, phone, additionalInfos[user].email);
        kycInfos[user].mobilePhoneNumber = phone;
        _setPhoneVerified(user, isVerified);
    }

    function setEmail(address user, string calldata email, bool isVerified) external onlyKycManager {
        _setProfileContact(user, kycInfos[user].mobilePhoneNumber, email);
        additionalInfos[user].email = email;
        _setEmailVerified(user, isVerified);
    }

    function grantAdminRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, user);
        _grantRole(MANAGER_ROLE, user);
    }

    function revokeAdminRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, user);
        _revokeRole(MANAGER_ROLE, user);
    }

    function grantManagerRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MANAGER_ROLE, user);
    }

    function revokeManagerRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MANAGER_ROLE, user);
    }

    function grantPlatformRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(RENTALITY_PLATFORM, user);
    }

    function grantHostRole(address user) external onlyPlatform {
        _grantRole(HOST_ROLE, user);
    }

    function revokeHostRole(address user) external onlyPlatform {
        _revokeRole(HOST_ROLE, user);
    }

    function grantGuestRole(address user) external onlyPlatform {
        _grantRole(GUEST_ROLE, user);
    }

    function revokeGuestRole(address user) external onlyPlatform {
        _revokeRole(GUEST_ROLE, user);
    }

    function setCivicData(address verifier, uint256 gatekeeperNetwork) external onlyAdmin {
        civicVerifier = verifier;
        civicGatekeeperNetwork = gatekeeperNetwork;
    }

    function setNewTCMessage(string calldata message) external onlyAdmin {
        termsMessageHash = ECDSA.toEthSignedMessageHash(bytes(message));
    }

    function setKycCommission(uint256 newCommission) external onlyAdmin {
        kycCommission = newCommission;
    }

    function getKycCommission() external view returns (uint256) {
        return kycCommission;
    }

    function useKycCommission(address user) external {
        require(hasRole(KYC_COMMISSION_MANAGER_ROLE, tx.origin) || msg.sender == user, 'only Commission manager');
        UserProfileCommissionRecord[] storage commissions = userToKycCommission[user];
        if (commissions.length == 0) {
            revert('not paid');
        }
        require(commissions[commissions.length - 1].commissionPaid, 'not paid');
        commissions[commissions.length - 1].commissionPaid = false;
    }

    function isCommissionPaidForUser(address user) external view returns (bool) {
        UserProfileCommissionRecord[] storage commissions = userToKycCommission[user];
        if (commissions.length == 0) {
            return false;
        }
        return commissions[commissions.length - 1].commissionPaid;
    }

    function payCommission(address user) external onlyPlatform {
        userToKycCommission[user].push(
            UserProfileCommissionRecord({paidTime: block.timestamp, commissionPaid: true})
        );
    }

    function manageRole(UserProfileRole newRole, address user, bool grant) external onlyAdmin {
        bytes32 role = _resolveRole(newRole);
        if (grant) {
            _grantRole(role, user);
        } else {
            _revokeRole(role, user);
        }
    }

    function getKYCProfile(address user) external view returns (UserProfileKYCInfo memory) {
        return kycInfos[user];
    }

    function getAdditionalProfile(address user) external view returns (UserProfileAdditionalInfo memory) {
        return additionalInfos[user];
    }

    function getPlatformUsersCount() external view returns (uint256) {
        return platformUsers.length;
    }

    function getPlatformUserAt(uint256 index) external view returns (address) {
        return platformUsers[index];
    }

    function getPlatformUsers() external view returns (address[] memory) {
        require(hasRole(ADMIN_VIEW_ROLE, tx.origin), 'Only Admin');
        return platformUsers;
    }

    function hasPassedKYC(address user) public view returns (bool) {
        IGatewayTokenVerifier verifier = IGatewayTokenVerifier(civicVerifier);
        return verifier.verifyToken(user, civicGatekeeperNetwork);
    }

    function hasPassedKYCAndTC(address user) public view returns (bool) {
        return profileConsents[user].accepted;
    }

    function isAdmin(address user) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }

    function isManager(address user) public view returns (bool) {
        return hasRole(MANAGER_ROLE, user);
    }

    function isRentalityPlatform(address user) public view returns (bool) {
        return hasRole(RENTALITY_PLATFORM, user);
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

    function isAdminViewRole(address user) public view returns (bool) {
        return hasRole(ADMIN_VIEW_ROLE, user);
    }

    function isSignatureManager(address user) public view returns (bool) {
        return hasRole(MANAGER_ROLE, user);
    }

    function isInvestorManager(address user) public view returns (bool) {
        return hasRole(INVESTMENT_MANAGER_ROLE, user);
    }

    function isOracleManager(address user) public view returns (bool) {
        return hasRole(ORACLE_MANAGER, user);
    }

    function _applyCivicKycInfo(address user, CivicUserProfileInfo calldata civicKycInfo, bool verifyEmail) internal {
        _touchPlatformUser(user);

        UserProfileKYCInfo storage kycInfo = kycInfos[user];
        kycInfo.surname = civicKycInfo.fullName;
        kycInfo.licenseNumber = civicKycInfo.licenseNumber;
        kycInfo.expirationDate = civicKycInfo.expirationDate;

        additionalInfos[user].email = civicKycInfo.email;
        additionalInfos[user].issueCountry = civicKycInfo.issueCountry;

        _setProfileContact(user, kycInfo.mobilePhoneNumber, civicKycInfo.email);
        if (verifyEmail) {
            _setEmailVerified(user, true);
        }
    }

    function _touchPlatformUser(address user) internal {
        _touchProfile(user);
        if (!userIsInPlatformList[user]) {
            userIsInPlatformList[user] = true;
            platformUsers.push(user);
        }
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

    function _sameString(string memory left, string memory right) internal pure returns (bool) {
        return keccak256(abi.encodePacked(left)) == keccak256(abi.encodePacked(right));
    }
}
