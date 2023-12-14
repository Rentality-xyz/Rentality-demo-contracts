// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RentalityPatrolEngine.sol";

contract RentalityHybridEngine is RentalityPatrolEngine {
    constructor(address _userService) RentalityPatrolEngine(_userService) {}
}