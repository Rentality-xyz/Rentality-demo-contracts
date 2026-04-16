// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BookingTypes.sol";
import "./IBooking.sol";

abstract contract BookingBase is IBooking {
    uint256 internal nextBookingId;

    mapping(uint256 => Booking) internal bookings;
    mapping(uint256 => uint256[]) internal resourceIdToActiveBookings;
    mapping(uint256 => uint256[]) internal resourceIdToBookings;
    mapping(address => uint256[]) internal userToBookings;
    mapping(address => uint256[]) internal userToActiveBookings;

    error BookingDoesNotExist(uint256 id);
    error InvalidBookingWindow(uint64 startDateTime, uint64 endDateTime);
    error InvalidBookingParties(address provider, address customer);

    event BookingCreated(uint256 indexed id, uint256 indexed resourceId, address indexed provider, address customer);
    event BookingWindowUpdated(uint256 indexed id, uint64 startDateTime, uint64 endDateTime);

    modifier bookingExists(uint256 id) {
        if (!exists(id)) {
            revert BookingDoesNotExist(id);
        }
        _;
    }

    function getBooking(uint256 id) external view virtual bookingExists(id) returns (Booking memory) {
        return bookings[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return bookings[id].id != 0;
    }

    function getProvider(uint256 id) external view virtual bookingExists(id) returns (address) {
        return bookings[id].provider;
    }

    function getCustomer(uint256 id) external view virtual bookingExists(id) returns (address) {
        return bookings[id].customer;
    }

    function _createBooking(
        uint256 resourceId,
        address provider,
        address customer,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal virtual returns (uint256) {
        _validateBooking(resourceId, provider, customer, startDateTime, endDateTime);

        uint256 id = ++nextBookingId;

        bookings[id] = Booking({
            id: id,
            resourceId: resourceId,
            customer: customer,
            provider: provider,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            createdAt: uint64(block.timestamp)
        });

        resourceIdToBookings[resourceId].push(id);
        resourceIdToActiveBookings[resourceId].push(id);
        userToBookings[provider].push(id);
        userToBookings[customer].push(id);
        userToActiveBookings[provider].push(id);
        userToActiveBookings[customer].push(id);

        emit BookingCreated(id, resourceId, provider, customer);
        return id;
    }

    function _updateBookingWindow(
        uint256 id,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal virtual bookingExists(id) {
        if (startDateTime >= endDateTime) {
            revert InvalidBookingWindow(startDateTime, endDateTime);
        }

        bookings[id].startDateTime = startDateTime;
        bookings[id].endDateTime = endDateTime;

        emit BookingWindowUpdated(id, startDateTime, endDateTime);
    }

    function _removeActiveBooking(uint256 resourceId, uint256 bookingId) internal virtual {
        uint256[] storage activeBookings = resourceIdToActiveBookings[resourceId];
        _removeBookingId(activeBookings, bookingId);
    }

    function _removeActiveBookingFromUser(address user, uint256 bookingId) internal virtual {
        uint256[] storage activeBookings = userToActiveBookings[user];
        _removeBookingId(activeBookings, bookingId);
    }

    function _validateBooking(
        uint256 resourceId,
        address provider,
        address customer,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal pure virtual {
        if (resourceId == 0 || provider == address(0) || customer == address(0) || provider == customer) {
            revert InvalidBookingParties(provider, customer);
        }

        if (startDateTime >= endDateTime) {
            revert InvalidBookingWindow(startDateTime, endDateTime);
        }
    }

    function _removeBookingId(uint256[] storage bookingIds, uint256 bookingId) internal virtual {
        uint256 length = bookingIds.length;

        for (uint256 i = 0; i < length; i++) {
            if (bookingIds[i] == bookingId) {
                bookingIds[i] = bookingIds[length - 1];
                bookingIds.pop();
                break;
            }
        }
    }
}
