// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/LibDiamond.sol";
import "../../../Schemas.sol";

contract RentalityUserService {
    function setKycInfo(
    string memory nickName,
    string memory mobilePhoneNumber,
    string memory profilePhoto,
    string memory email,
    bytes memory TCSignature,
    address user
  ) public {
          LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
          ds.kycInfo[user] = Schemas.KYCInfo(
            nickName,
            mobilePhoneNumber,
            profilePhoto,
            email,
            TCSignature
          );
  }
}