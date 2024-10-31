// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import './abstract/IRentalityAccessControl.sol';
import './proxy/UUPSAccess.sol';
import './Schemas.sol';

/// @title RentalityChatHelper
/// @notice A contract to manage chat key pairs for users
/// @dev Users can set and retrieve their chat key pairs, and get public keys of specified addresses.
contract RentalityChatHelper is Initializable, UUPSAccess {
  // Mapping to store chat key pairs associated with Ethereum addresses
  mapping(address => Schemas.ChatKeyPair) private addressToChatKeyPair;

  /// @notice Set the chat key pair for the calling user
  /// @param chatPrivateKey The private chat key of the user
  /// @param chatPublicKey The public chat key of the user
  function setMyChatPublicKey(string memory chatPrivateKey, string memory chatPublicKey) public {
    addressToChatKeyPair[msg.sender] = Schemas.ChatKeyPair(chatPrivateKey, chatPublicKey);
  }

  /// @notice Get the chat key pair of the calling user
  /// @return The private and public chat keys of the calling user
  function getMyChatKeys() public view returns (string memory, string memory) {
    return (addressToChatKeyPair[msg.sender].privateKey, addressToChatKeyPair[msg.sender].publicKey);
  }

  /// @notice Get the public chat keys associated with specified addresses
  /// @param addresses An array of Ethereum addresses
  /// @return An array of AddressPublicKey structs containing user addresses and their public chat keys
  function getChatPublicKeys(address[] memory addresses) public view returns (Schemas.AddressPublicKey[] memory) {
    Schemas.AddressPublicKey[] memory result = new Schemas.AddressPublicKey[](addresses.length);

    for (uint i = 0; i < addresses.length; i++) {
      result[i] = Schemas.AddressPublicKey(addresses[i], addressToChatKeyPair[addresses[i]].publicKey);
    }

    return result;
  }

  /// @notice contract initialization function
  /// @param _userService address to RentalityUserService
  function initialize(address _userService) public virtual initializer {
    userService = IRentalityAccessControl(_userService);
  }
}
