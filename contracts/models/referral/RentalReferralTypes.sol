// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../base/referral/ReferralTypes.sol';

struct RentalReferralCallbackArgs {
    uint256 tripId;
    uint256 carId;
    address counterparty;
}
