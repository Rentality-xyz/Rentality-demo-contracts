// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../models/base/booking/BookingBase.sol';

/// Exposes BookingBase's internals so the window rules can be tested without a whole platform around them.
contract ExclusiveBookingHarness is BookingBase {
  function book(
    uint256 resourceId,
    address provider,
    address customer,
    uint64 startDateTime,
    uint64 endDateTime
  ) external returns (uint256) {
    return _createBooking(resourceId, provider, customer, startDateTime, endDateTime);
  }

  function move(uint256 id, uint64 startDateTime, uint64 endDateTime) external {
    _updateBookingWindow(id, startDateTime, endDateTime);
  }

  function release(uint256 id) external {
    _releaseBooking(id);
  }
}

/// The other half of the rule: a model that wants overlapping requests, as TripMain does.
contract OpenBookingHarness is ExclusiveBookingHarness {
  function _bookingsAreExclusive() internal pure override returns (bool) {
    return false;
  }
}
