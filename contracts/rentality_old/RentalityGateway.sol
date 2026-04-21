// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../gateway/AppGateway.sol';

/// @notice Compatibility name for existing scripts/tests while the external entrypoint migrates to AppGateway.
contract RentalityGateway is AppGateway {}
