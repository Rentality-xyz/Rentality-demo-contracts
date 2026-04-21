// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



import './RentalityPetrolEngine.sol';

/// @title RentalityHybridEngine - Implementation of a hybrid engine in the Rentality system.
/// @notice This contract extends RentalityPetrolEngine.sol and represents a hybrid engine type.
contract RentalityHybridEngine is RentalityPetrolEngine {
  /// @dev Constructor to set the profile/access-control service address during deployment.
  /// @param _userService The address of the profile/access-control service.
  constructor(address _userService) RentalityPetrolEngine(_userService) {}
}

