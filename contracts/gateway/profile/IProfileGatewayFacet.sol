// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../models/common/CommonTypes.sol';
import '../../models/profile/UserProfileTypes.sol';

interface IProfileGatewayFacet {
  function getMyFullKYCInfo() external view returns (GatewayFullUserProfileInfo memory);
  function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage) external view returns (GatewayAdminUserProfilePage memory);
  function getPlatformUsersInfo(uint256 page, uint256 itemsPerPage) external view returns (GatewayAdminUserProfilePage memory);
  function getUserFullKYCInfo(address user) external view returns (GatewayFullUserProfileInfo memory);
  function getUserCurrency(address user) external view returns (UserCurrencyInfo memory);
  function getKycCommission() external view returns (uint256);
  function calculateKycCommission(address currency) external view returns (uint256);
  function getPlatformInfo() external view returns (PlatformInfoDTO memory);
  function isKycCommissionPaid(address user) external view returns (bool);
  function payKycCommission(address currency) external payable;
  function addUserCurrency(address currency) external;
  function setKYCInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory tcSignature,
    bytes4 hash
  ) external;
  function setPhoneNumber(address user, string memory phone, bool isVerified) external;
  function setEmail(address user, string memory email, bool isVerified) external;
  function setCivicKYCInfo(address user, GatewayCivicUserProfileInfo memory civicKycInfo) external;
  function setCivicData(address civicVerifier, uint256 civicGatekeeperNetwork) external;
  function setKycCommission(uint256 value) external;
  function manageRole(UserProfileRole role, address user, bool grant) external;
  function setPushToken(address user, string memory pushToken) external;
  function useKycCommission(address user) external;
}
