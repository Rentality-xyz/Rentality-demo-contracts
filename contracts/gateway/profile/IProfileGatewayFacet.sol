// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../../rentality_old/Schemas.sol';

interface IProfileGatewayFacet {
  function getMyFullKYCInfo() external view returns (Schemas.FullKYCInfoDTO memory);
  function getPlatformUsersKYCInfos(uint256 page, uint256 itemsPerPage) external view returns (Schemas.AdminKYCInfosDTO memory);
  function getUserFullKYCInfo(address user) external view returns (Schemas.FullKYCInfoDTO memory);
  function getKycCommission() external view returns (uint256);
  function isKycCommissionPaid(address user) external view returns (bool);
  function payKycCommission(address currency) external payable;
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
  function setCivicKYCInfo(address user, Schemas.CivicKYCInfo memory civicKycInfo) external;
  function setPushToken(address user, string memory pushToken) external;
  function useKycCommission(address user) external;
}
