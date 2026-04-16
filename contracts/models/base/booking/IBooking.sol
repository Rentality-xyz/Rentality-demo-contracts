// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BookingTypes.sol";

interface IBooking {
    function getBooking(uint256 id) external view returns (Booking memory);

    function exists(uint256 id) external view returns (bool);

    function getProvider(uint256 id) external view returns (address);

    function getCustomer(uint256 id) external view returns (address);
}
