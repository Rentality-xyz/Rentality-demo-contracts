// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import {EIP712Upgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

/// @title Rentality Geo Service Contract
/// @notice This contract provides geolocation services.
/// @dev It interacts with an external geolocation API and stores the results for cars.
contract RentalityLocationVerifier is EIP712Upgradeable, UUPSAccess {
  address private adminAddress;

  function verifySignedLocationInfo(Schemas.SignedLocationInfo memory locationInfo) public view {
    // require(_verify(locationInfo) == adminAddress, 'Wrong signature');
  }

  function _verify(Schemas.SignedLocationInfo memory location) internal view returns (address) {
    bytes32 digest = _hash(location.locationInfo);
    return ECDSA.recover(digest, location.signature);
  }
  function verify(Schemas.SignedLocationInfo memory location) public view returns (address) {
    bytes32 digest = _hash(location.locationInfo);
    return ECDSA.recover(digest, location.signature);
  }

  function _hash(Schemas.LocationInfo memory location) internal view returns (bytes32) {
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

  function initialize(address _userService, address admin) public initializer {
    userService = IRentalityAccessControl(_userService);
    adminAddress = admin;
    __EIP712_init('RentalityLocationVerifier', '1');
  }
}
