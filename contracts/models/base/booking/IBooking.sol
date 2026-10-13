// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BookingTypes.sol";

interface IBooking {
    function getBooking(uint256 id) external view returns (Booking memory);

    function exists(uint256 id) external view returns (bool);

    function getProvider(uint256 id) external view returns (address);

    function getCustomer(uint256 id) external view returns (address);

    function isWindowFree(uint256 resourceId, uint64 startDateTime, uint64 endDateTime) external view returns (bool);

    function isBookedAt(uint256 resourceId, uint64 timestamp) external view returns (bool);

    function getActiveBookings(uint256 resourceId) external view returns (uint256[] memory);
}
