// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../../models/common/CommonTypes.sol';
import '../upgradeable/UUPSOwnable.sol';

interface IRentalityLocationVerifierAccess {
  function isAdmin(address user) external view returns (bool);
}

contract RentalityLocationVerifier is EIP712Upgradeable, UUPSOwnable {
  IRentalityLocationVerifierAccess public userAccess;
  address private adminAddress;

  constructor() {
    _disableInitializers();
  }

  function initialize(address userAccessAddress, address admin) public initializer {
    __Ownable_init();
    __EIP712_init('RentalityLocationVerifier', '1');
    userAccess = IRentalityLocationVerifierAccess(userAccessAddress);
    adminAddress = admin;
  }

  function verifySignedLocationInfo(SignedLocationInfo memory locationInfo) public view {
    if (locationInfo.signature.length == 0) {
      return;
    }
    require(_verify(locationInfo) == adminAddress, 'Wrong signature');
  }

  function verify(SignedLocationInfo memory location) public view returns (address user) {
    return _verify(location);
  }

  function updateAdmin(address admin) external {
    require(userAccess.isAdmin(msg.sender) || msg.sender == owner(), 'Only admin');
    adminAddress = admin;
  }

  function updateUserAccess(address userAccessAddress) external onlyOwner {
    userAccess = IRentalityLocationVerifierAccess(userAccessAddress);
  }

  function _verify(SignedLocationInfo memory location) internal view returns (address) {
    bytes32 digest = _hash(location.locationInfo);
    return ECDSA.recover(digest, location.signature);
  }

  function _hash(LocationInfo memory location) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              'LocationInfo(string userAddress,string country,string state,string city,string latitude,string longitude,string timeZoneId)'
            ),
            keccak256(bytes(location.userAddress)),
            keccak256(bytes(location.country)),
            keccak256(bytes(location.state)),
            keccak256(bytes(location.city)),
            keccak256(bytes(location.latitude)),
            keccak256(bytes(location.longitude)),
            keccak256(bytes(location.timeZoneId))
          )
        )
      );
  }
}
