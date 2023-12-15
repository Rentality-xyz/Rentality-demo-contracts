// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityPatrolEngine.sol";

/// @title RentalityHybridEngine - Implementation of a hybrid engine in the Rentality system.
/// @notice This contract extends RentalityPatrolEngine and represents a hybrid engine type.
contract RentalityHybridEngine is RentalityPatrolEngine {

    /// @dev Constructor to set the RentalityUserService address during deployment.
    /// @param _userService The address of the RentalityUserService contract.
    constructor(address _userService) RentalityPatrolEngine(_userService) {}
}
