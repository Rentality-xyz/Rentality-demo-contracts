// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './IRentalityAccessControl.sol';
import '../../models/common/Schemas.sol';

interface ILegacyUserProfileSource is IRentalityAccessControl {
  function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);

  function getMyFullKYCInfo(address user) external view returns (Schemas.FullKYCInfoDTO memory);

  function hasPassedKYCAndTC(address user) external view returns (bool);
}
